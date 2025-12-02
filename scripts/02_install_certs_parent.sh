#!/bin/bash
set -e

echo " Generating Parent Root + Intermediate CA..."

CERT_DIR=~/automation/generated_certs
sudo mkdir -p $CERT_DIR
sudo chmod 777 $CERT_DIR

# Root CA
openssl genrsa -out $CERT_DIR/root-ca.key.pem 4096
openssl req -x509 -new -nodes -key $CERT_DIR/root-ca.key.pem -sha256 -days 3650 \
  -subj "/CN=Azure_IoT_Hub_CA_Test_Only" \
  -out $CERT_DIR/root-ca.cert.pem

# Parent CA
openssl genrsa -out $CERT_DIR/parent-ca.key.pem 4096
openssl req -new -key $CERT_DIR/parent-ca.key.pem \
  -subj "/CN=${PARENT_DEVICE_ID}" \
  -out $CERT_DIR/parent-ca.csr

openssl x509 -req -in $CERT_DIR/parent-ca.csr \
  -CA $CERT_DIR/root-ca.cert.pem \
  -CAkey $CERT_DIR/root-ca.key.pem \
  -CAcreateserial \
  -out $CERT_DIR/parent-ca.cert.pem \
  -days 3650 -sha256

#  Copy into aziot directories with permissions
sudo mkdir -p /var/aziot/certs /var/aziot/cert_keys
sudo cp $CERT_DIR/parent-ca.cert.pem /var/aziot/certs/
sudo cp $CERT_DIR/parent-ca.key.pem /var/aziot/cert_keys/
sudo chmod 644 /var/aziot/certs/parent-ca.cert.pem
sudo chmod 600 /var/aziot/cert_keys/parent-ca.key.pem

echo " Parent CA installed successfully"
