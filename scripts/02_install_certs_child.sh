#!/bin/bash
set -e

CHILD_DEVICE_ID=${CHILD_DEVICE_ID:-child-edge-device}
WORK_DIR=/home/$USER/automation/certs_work

sudo mkdir -p /var/aziot/certs /var/aziot/cert_keys
mkdir -p $WORK_DIR

# Parent CA references
PARENT_CA_CERT="/var/aziot/certs/iot-edge-device-ca-Parent-cert-full-chain.cert.pem"
PARENT_CA_KEY="/var/aziot/cert_keys/iot-edge-device-ca-Parent-cert.key.pem"

# Output file names
CHILD_CERT="$WORK_DIR/iot-edge-device-ca-${CHILD_DEVICE_ID}-full-chain.cert.pem"
CHILD_KEY="$WORK_DIR/iot-edge-device-ca-${CHILD_DEVICE_ID}.key.pem"

echo "🔹 Generating CHILD private key..."
openssl genrsa -out $CHILD_KEY 4096

echo "🔹 Creating CHILD certificate signed by PARENT CA..."
openssl req -new -key $CHILD_KEY -subj "/CN=${CHILD_DEVICE_ID}" \
 | openssl x509 -req -CA $PARENT_CA_CERT -CAkey $PARENT_CA_KEY -CAcreateserial \
 -out $CHILD_CERT -days 365 -sha256

# Move certs to runtime with correct owners
echo "🔹 Installing certs into IoT Edge runtime..."
sudo cp $CHILD_CERT /var/aziot/certs/
sudo cp $CHILD_KEY /var/aziot/cert_keys/

sudo chown aziotcs:aziotcs /var/aziot/certs/*
sudo chown aziotks:aziotks /var/aziot/cert_keys/*
sudo chmod 644 /var/aziot/certs/*
sudo chmod 600 /var/aziot/cert_keys/*

echo "✔ Child certificate created successfully"
