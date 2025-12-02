#!/usr/bin/env bash
set -euo pipefail

echo " Applying config on CHILD..."

if [ ! -f "$HOME/automation/config.toml" ]; then
  echo " config.toml not found in ~/automation"
  exit 1
fi

sudo mkdir -p /etc/aziot
sudo cp "$HOME/automation/config.toml" /etc/aziot/config.toml
sudo chown root:root /etc/aziot/config.toml
sudo chmod 644 /etc/aziot/config.toml

sudo iotedge config apply
sudo iotedge system restart

echo "⏱ Waiting 10s for services..."
sleep 10

sudo iotedge system status || true
echo "✔ Child setup complete."
