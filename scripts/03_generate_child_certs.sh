#!/bin/bash
set -e

echo " Generating Child cert signed by Parent CA..."

CERT_DIR=~/automation/generated_certs
sudo mkdir -p $CERT_DIR
sudo chmod 777 $CERT_DIR

CHILD_CERT=$CERT_DIR/child-${CHILD_DEVICE_ID}.cert.pem
CHILD_KEY=$CERT_DIR/child-${CHILD_DEVICE_ID}.key.pem

openssl genrsa -out $CHILD_KEY 4096
openssl req -new -key $CHILD_KEY \
  -subj "/CN=${CHILD_DEVICE_ID}" \
  -out $CERT_DIR/child-${CHILD_DEVICE_ID}.csr

# IMPORTANT — Parent CA path must match where we copied earlier
openssl x509 -req -in $CERT_DIR/child-${CHILD_DEVICE_ID}.csr \
  -CA /var/aziot/certs/parent-ca.cert.pem \
  -CAkey /var/aziot/cert_keys/parent-ca.key.pem \
  -CAcreateserial \
  -out $CHILD_CERT \
  -days 1825 -sha256

echo " Child certificate created"

# Prepare transfer bundle
EXPORT_DIR=~/child_export
mkdir -p $EXPORT_DIR
cp $CHILD_CERT $EXPORT_DIR/
cp $CHILD_KEY  $EXPORT_DIR/
chmod 644 $EXPORT_DIR/*
echo " Export directory ready for SCP"
