#!/bin/bash

username="{iot-edge-username}"
ipaddress="{iot-edge-ipaddress}"

# UPLOAD HELPER SCRIPT TO IOT EDGE DEVICE
scp -r -p ~/setup-iot-edge-gateway.sh $username@$ipaddress:~/
# CONFIGURE AZURE IOT EDGE TRANSPARENT GATEWAY
ssh $username@$ipaddress 'sudo bash ~/setup-iot-edge-gateway.sh'
# DOWNLOAD X.509 CERTIFICATE
scp -r -p $username@$ipaddress:/etc/iotedge-certificates/certs/azure-iot-test-only.root.ca.cert.pem .

download azure-iot-test-only.root.ca.cert.pem
