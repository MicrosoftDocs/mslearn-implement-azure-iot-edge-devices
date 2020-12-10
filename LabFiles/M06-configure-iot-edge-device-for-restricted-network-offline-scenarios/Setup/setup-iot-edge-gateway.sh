#!/bin/bash

# SCRIPT DESCRIPTION:
#
# This is a helper script to automate the configuation of the Azure IoT Edge
# Transparent Gateway.
#
# This script will configure the following items:
# - Generate and Configure Root CA and Device x.509 certificates for child
#   device authentication
# - Azure IoT Edge Device Connection String
# - Azure IoT Edge Device Hostname
#

connectionstring="{iot-edge-device-connection-string}"
hostname="{iot-edge-device-hostname}"


configFile="/etc/iotedge/config.yaml"
certGenDirectory="/etc/iotedge-certificates"

# CLONE Azure/iotedge GITHUB PROJECT TO GET certGen.sh HELPER SCRIPT FOR GENERATING X.509 CERTIFICATES
echo "Cloning Azure/iotedge repository to get certGen.sh helper script..."
cd ~
git clone https://github.com/Azure/iotedge.git

# CREATE '/etc/iotedge-certificates' DIRECTORY
echo "Copying certGen.sh script to $certGenDirectory..."
sudo mkdir $certGenDirectory
cd $certGenDirectory

# COPY certGen.sh HELPER SCRIPT TO '/etc/iotedge-certificates' DIRECTORY
sudo cp ~/iotedge/tools/CACertificates/*.cnf .
sudo cp ~/iotedge/tools/CACertificates/certGen.sh .

# MAKE SURE certGen.sh SCRIPT IS MARKED AS EXECUTABLE
sudo chmod 700 certGen.sh

# GENERATE ROOT CA X.509 CERTIFICATE
echo "Generating Root CA x.509 certificate..."
./certGen.sh create_root_and_intermediate

# GENREATE IOT EDGE DEVICE CA CERTIFICATE
echo "Generating IoT Edge Device CA Certificate..."
./certGen.sh create_edge_device_ca_certificate "IoTEdgeGatewayCA"

# ENSURE CONFIG.YAML FILE IS NOT READONLY
chmod a+w $configFile

# CONFIGURE IOT EDGE ROOT CA AND DEVICE CERTIFICATES
echo "Configuring IoT Edge Root CA and Device x.509 certificates in config.yaml..."
deviceCACert="$certGenDirectory/certs/iot-edge-device-ca-IoTEdgeGatewayCA-full-chain.cert.pem"
deviceCAPrivateKey="$certGenDirectory/private/iot-edge-device-ca-IoTEdgeGatewayCA.key.pem"
trustedCACert="$certGenDirectory/certs/azure-iot-test-only.root.ca.cert.pem"
# certificates:
sed -i 's/# certificates:/certificates:/g' $configFile
#   device_ca_cert: "<ADD PATH TO DEVICE CA CERTIFICATE HERE>"
sed -i "s#\(device_ca_cert: \).*#\1\"$deviceCACert\"#g" $configFile
sed -i 's/#   device_ca_cert:/  device_ca_cert:/g' $configFile
#   device_ca_pk: "<ADD PATH TO DEVICE CA PRIVATE KEY HERE>"
sed -i "s#\(device_ca_pk: \).*#\1\"$deviceCAPrivateKey\"#g" $configFile
sed -i 's/#   device_ca_pk:/  device_ca_pk:/g' $configFile
#   trusted_ca_certs: "<ADD PATH TO TRUSTED CA CERTIFICATES HERE>"
sed -i "s#\(trusted_ca_certs: \).*#\1\"$trustedCACert\"#g" $configFile
sed -i 's/#   trusted_ca_certs:/  trusted_ca_certs:/g' $configFile


# CONFIGURE IOT EDGE HOSTNAME
echo "Configuring IoT Edge Device Hostname in config.yaml..."
sed -i "s#\(hostname: \).*#\1\"$hostname\"#g" $configFile


# CONFIGURE IOT EDGE DEVICE
echo "Coniguring IoT Edge Device with Connection String..."
sudo bash /etc/iotedge/configedge.sh $connectionstring

echo "IoT Edge Transparent Gateway has been configured!"

echo ""
echo "Location of the Root CA x.509 certificate to use for authenticating child device(s):"
echo ""
echo "$certGenDirectory/certs/azure-iot-test-only.root.ca.cert.pem"
echo ""
