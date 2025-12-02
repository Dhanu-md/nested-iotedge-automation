#!/bin/bash
set -e

CHILD_DEVICE_ID=${CHILD_DEVICE_ID:-child-iotedge-01p}

CERTS=/var/aziot/certs
KEYS=/var/aziot/cert_keys

mkdir -p $CERTS $KEYS

# Generate child CA cert from Parent CA
openssl req -newkey rsa:4096 -nodes \
    -keyout $KEYS/iot-edge-device-ca-${CHILD_DEVICE_ID}.key.pem \
    -subj "/CN=${CHILD_DEVICE_ID}.ca" \
    -out $CERTS/${CHILD_DEVICE_ID}.csr.pem

openssl x509 -req \
    -in $CERTS/${CHILD_DEVICE_ID}.csr.pem \
    -CA $CERTS/iot-edge-device-ca-Parent-cert-full-chain.cert.pem \
    -CAkey $KEYS/iot-edge-device-ca-Parent-cert.key.pem \
    -CAcreateserial \
    -out $CERTS/iot-edge-device-ca-${CHILD_DEVICE_ID}.cert.pem \
    -days 365 \
    -sha256

# Build child full chain
cat \
  $CERTS/iot-edge-device-ca-${CHILD_DEVICE_ID}.cert.pem \
  $CERTS/iot-edge-device-ca-Parent-cert-full-chain.cert.pem \
  > $CERTS/iot-edge-device-ca-${CHILD_DEVICE_ID}-full-chain.cert.pem

chmod 644 $CERTS/*child* || true
chmod 600 $KEYS/*child* || true
echo "✔ Child certs generated"
