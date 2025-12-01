#!/usr/bin/env bash
set -euo pipefail

echo "[CLEANUP] Stopping IoT Edge services (if any)..."
sudo iotedge system stop 2>/dev/null || true
sudo aziotctl stop 2>/dev/null || true

echo "[CLEANUP] Removing Edge containers..."
if command -v docker >/dev/null 2>&1; then
  sudo docker rm -f $(sudo docker ps -aq --filter "label=net.azure-devices.edge.owner=Microsoft.Azure.Devices.Edge.Agent") 2>/dev/null || true
fi

echo "[CLEANUP] Removing IoT Edge state dirs..."
sudo rm -rf /var/lib/aziot 2>/dev/null || true
sudo rm -rf /var/lib/iotedge 2>/dev/null || true

echo "[CLEANUP] Removing IoT Edge certs & secrets..."
sudo rm -rf /var/aziot/certs/* 2>/dev/null || true
sudo rm -rf /var/aziot/secrets/* 2>/dev/null || true

echo "[CLEANUP] Removing IoT Edge config..."
sudo rm -f /etc/aziot/config.toml 2>/dev/null || true

echo "[CLEANUP] Removing previously trusted custom CA certs..."
sudo rm -f /usr/local/share/ca-certificates/iot-*.crt 2>/dev/null || true
sudo update-ca-certificates || true

echo "[CLEANUP] Done."
