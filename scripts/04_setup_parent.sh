#!/bin/bash
set -e

echo "🔹 Applying IoT Edge parent config and restarting service..."
sudo iotedge config apply -y || sudo aziotctl config apply -y
sleep 5
sudo systemctl restart aziot-edged
