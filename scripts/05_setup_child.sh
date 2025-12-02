#!/bin/bash
set -e

echo "🔹 Applying IoT Edge child config and restarting service..."

sudo mkdir -p /var/aziot/certs /var/aziot/cert_keys
sudo cp ~/child_received_certs/*.cert.pem /var/aziot/certs/ || true
sudo cp ~/child_received_certs/*.key.pem /var/aziot/cert_keys/ || true
sudo chmod 644 /var/aziot/certs/* || true
sudo chmod 600 /var/aziot/cert_keys/* || true

sudo iotedge config apply -y || sudo aziotctl config apply -y
sleep 5
sudo systemctl restart aziot-edged
