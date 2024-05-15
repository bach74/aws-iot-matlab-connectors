## 1. Create a new policy

```bash
aws iot create-policy --policy-name my-iot-policy --policy-document file://my-iot-policy.json --region eu-central-1
```


## 2. device provisionig

To provision a device use
```bash
./provision.sh device1 my-iot-policy
```

The script then
- creates a private key
- sends a CSR to AWS IoT Core to create a certificate with CN=<device-name>
- attaches the policy <policy-name> to the certificate
- creates a thing with name <device-name>
- sets the certificate to ACTIVE
- gets the rest endpoint
- downloads the Amazon Root CA
- provides a command to connect to the mqtt device from Matlab <-- use this in Matlab to connect to the AWS IoT MQTT endpoint
