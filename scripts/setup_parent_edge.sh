#!/usr/bin/env bash
set -euo pipefail

### === CONFIG: EDIT THESE ===
IOTHUB_HOSTNAME="iotHub-prod-in2.azure-devices.net"
PARENT_DEVICE_ID="parent-iotedge-01p"
PARENT_CONN_STRING="$PARENT_EDGE_DEVICE_CONNECTION_STRING"
PARENT_HOSTNAME="parent-iotedge-01p"

OS_CODENAME="jammy"   # Ubuntu 22.04
### ==========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[PARENT] Running cleanup first..."
bash "$SCRIPT_DIR/cleanup_iotedge.sh"

echo "[PARENT] Setting hostname to $PARENT_HOSTNAME..."
sudo hostnamectl set-hostname "$PARENT_HOSTNAME"

echo "[PARENT] Installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl git jq

echo "[PARENT] Installing Moby (Docker)..."
curl https://packages.microsoft.com/config/ubuntu/$OS_CODENAME/multiarch/prod.list | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
sudo apt-get update -y
sudo apt-get install -y moby-engine moby-cli

echo "[PARENT] Installing Azure IoT Edge runtime..."
sudo apt-get install -y aziot-edge

echo "[PARENT] Preparing cert directories..."
sudo mkdir -p /var/aziot/certs /var/aziot/secrets
sudo chown -R "$USER":"$USER" /var/aziot/certs /var/aziot/secrets

echo "[PARENT] Cloning IoT Edge cert tools..."
mkdir -p ~/iotedge-certs
cd ~/iotedge-certs
if [ ! -d "iotedge" ]; then
  git clone https://github.com/Azure/iotedge.git
fi
cd iotedge/tools/CACertificates

echo "[PARENT] Generating root + intermediate CA (TEST ONLY)..."
./certGen.sh create_root_and_intermediate

echo "[PARENT] Generating parent device CA..."
./certGen.sh create_edge_device_ca_certificate "Parent"

echo "[PARENT] Generating child device CA (to be used on child box)..."
./certGen.sh create_edge_device_ca_certificate "child"

# Paths from certGen structure
CERTS_DIR="$(pwd)/certs"
PRIVATE_DIR="$(pwd)/private"

PARENT_CERT_SRC="$CERTS_DIR/iot-edge-device-ca-Parent-cert-full-chain.cert.pem"
PARENT_KEY_SRC="$PRIVATE_DIR/iot-edge-device-ca-Parent-cert.key.pem"
CHILD_CERT_SRC="$CERTS_DIR/iot-edge-device-ca-child-cert-full-chain.cert.pem"
CHILD_KEY_SRC="$PRIVATE_DIR/iot-edge-device-ca-child-cert.key.pem"
ROOT_CA_SRC="$CERTS_DIR/azure-iot-test-only.root.ca.cert.pem"

echo "[PARENT] Copying parent certs to /var/aziot..."
sudo cp "$PARENT_CERT_SRC" /var/aziot/certs/
sudo cp "$PARENT_KEY_SRC" /var/aziot/secrets/
sudo cp "$ROOT_CA_SRC" /var/aziot/certs/

sudo chown aziotcs:aziotcs /var/aziot/certs/*.pem
sudo chown aziotks:aziotks /var/aziot/secrets/*.pem
sudo chmod 644 /var/aziot/certs/*.pem
sudo chmod 600 /var/aziot/secrets/*.pem

echo "[PARENT] Exporting child cert/key for later transfer..."
sudo mkdir -p /var/aziot/child_export
sudo cp "$CHILD_CERT_SRC" /var/aziot/child_export/
sudo cp "$CHILD_KEY_SRC" /var/aziot/child_export/
sudo cp "$ROOT_CA_SRC" /var/aziot/child_export/

echo "[PARENT] Writing /etc/aziot/config.toml..."
sudo tee /etc/aziot/config.toml > /dev/null <<EOF
auto_reprovisioning_mode = "OnErrorOnly"
hostname = "$PARENT_HOSTNAME"
trust_bundle_cert = "file:///var/aziot/certs/azure-iot-test-only.root.ca.cert.pem"
prefer_module_identity_cache = false

[edge_ca]
cert = "file:///var/aziot/certs/iot-edge-device-ca-Parent-cert-full-chain.cert.pem"
pk   = "file:///var/aziot/secrets/iot-edge-device-ca-Parent-cert.key.pem"

[provisioning]
source = "manual"
connection_string = "$PARENT_CONN_STRING"

[agent]
name = "edgeAgent"
type = "docker"
imagePullPolicy = "on-create"

[agent.config]
image = "mcr.microsoft.com/azureiotedge-agent:1.5"
EOF

echo "[PARENT] Applying IoT Edge config..."
sudo iotedge config apply

echo "[PARENT] Restarting IoT Edge..."
sudo iotedge system restart

echo "[PARENT] Setup complete. Check with: iotedge system status && iotedge list"
