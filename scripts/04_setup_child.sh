#!/bin/bash
set -e

echo " Installing certs for child"
sudo mkdir -p /var/aziot/certs /var/aziot/cert_keys
sudo cp ~/child_received_certs/*full-chain*.pem /var/aziot/certs/
sudo cp ~/child_received_certs/*key*.pem /var/aziot/cert_keys/

sudo chmod 644 /var/aziot/certs/*
sudo chmod 600 /var/aziot/cert_keys/*

echo " Applying config"
sudo cp ~/config.toml /etc/aziot/config.toml
sudo iotedge config apply
sudo iotedge system restart

echo "✔ Child deployment complete"
