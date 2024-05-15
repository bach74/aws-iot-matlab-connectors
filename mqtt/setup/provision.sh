#!/bin/bash
# USAGE: ./provision.sh <device-name> <policy-name> <region>

if [ "$#" -ne 3 ]; then
    echo "USAGE: ./provision.sh <device-name> <policy-name> <region>"
	exit 2
fi

DEVICE_CERT_NAME=$1

POLICY_NAME=$2

REGION=$3

CERTS_DIR=$(dirname $(pwd))/certs

mkdir -p ${CERTS_DIR}

echo "Create a P256 Private key..."
openssl ecparam -name prime256v1 -genkey -noout -out ${CERTS_DIR}/${DEVICE_CERT_NAME}.key.pem

echo "Create a CSR..."
openssl req -new \
	-key ${CERTS_DIR}/${DEVICE_CERT_NAME}.key.pem \
	-out ${CERTS_DIR}/${DEVICE_CERT_NAME}.csr \
	-subj "/C=US/ST=Washington/L=Seattle/O=Octank/OU=ACME/CN=${DEVICE_CERT_NAME}"

echo "Ask AWS IoT Core to create the certificate from the CSR..."
aws iot create-certificate-from-csr \
    --certificate-signing-request file://${CERTS_DIR}/${DEVICE_CERT_NAME}.csr \
    --certificate-pem-outfile ${CERTS_DIR}/${DEVICE_CERT_NAME}.pem > tmp \
    --region ${REGION}
    
CERT_ARN=$(cat tmp | jq -r .certificateArn)
CERT_ID=$(cat tmp | jq -r .certificateId)

echo "Attach policy..."
aws iot attach-policy \
	--policy-name ${POLICY_NAME} \
	--target ${CERT_ARN} \
	--region ${REGION}

echo "create a thing instance..."
aws iot create-thing \
	--region ${REGION} \
	--thing-name ${DEVICE_CERT_NAME}

echo "attach the certificate to your thing..."
aws iot attach-thing-principal \
	--region ${REGION} \
	--thing-name ${DEVICE_CERT_NAME} \
	--principal ${CERT_ARN}
	
echo "set certificate to ACTIVE..."
aws iot update-certificate \
	--certificate-id ${CERT_ID} \
	--new-status "ACTIVE" \
	--region ${REGION}
	
echo "clean up..."
rm ${CERTS_DIR}/${DEVICE_CERT_NAME}.csr
rm tmp

echo "get AmazonRootCA"
curl -o ../certs/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
chmod 644 ../certs/AmazonRootCA1.pem

echo "get rest api URL"
aws iot describe-endpoint --endpoint-type iot:Data-ATS > tmp

REST_API=$(cat tmp | jq -r .endpointAddress)

echo "To connect to this device from Matlab, enter this command in Matlab"
printf "myMQTT = mqttclient('ssl://${REST_API}', ...
CARootCertificate = '${CERTS_DIR}/AmazonRootCA1.pem', ...
ClientCertificate = '${CERTS_DIR}/${DEVICE_CERT_NAME}.pem', ...
ClientKey = '${CERTS_DIR}/${DEVICE_CERT_NAME}.key.pem');\n"
