function out  = opcua_output(in, serverIp, serverPort) 
% define variables 
persistent uaClient;
persistent nodes;
persistent prevTime;
 
% initialize variables
% OPC UA server address, port and connect client (Simulink) to the server 
if isempty(uaClient)
    prevTime = 0;
    uaClient = opcua(char(serverIp), serverPort);
    connect(uaClient);
else
    % define nodes on the server that are going to be read
    if isempty(nodes) && if uaClient.isConnected
        prevTime = 0;
        % read out the variables of the OPC UA server 
        % you can also try to find the nodes, eg. doubleNode = findNodeByName(dataItemsNode,'DoubleDataItem');
        %% TODO CUSTOMIZE FOR YOUR VALUES
        nodeWindSpeed = opcuanode(0,53951,uaClient);
        nodeWindDirection = opcuanode(0,53952,uaClient);
        nodeGenSpeedRPM = opcuanode(0,53949,uaClient);
        nodeGenTorque = opcuanode(0,53950,uaClient);
        nodeGenPWR = opcuanode(0,53958,uaClient);
        nodeRotorSpeedRPM = opcuanode(0,53957,uaClient);
        nodes = [nodeWindSpeed nodeWindDirection nodeGenSpeedRPM nodeGenTorque nodeGenPWR nodeRotorSpeedRPM];
        %% END CUSTOMIZE
    else 
        % read and write variables of the server, but only every 0.1 sec
        if  ((in(1)-prevTime)>0.1)
            prevTime = in(1);
            writeValue(uaClient, nodes, {x(2),x(3),x(4),x(5),x(6),x(7)});
        end 
    end
end
% assign values to the output variable (out) of this function (eg. for logging)
out = in;
end