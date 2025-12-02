#!/bin/bash
set -e

sudo apt-get update
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update;
sudo apt-get install moby-engine
sudo apt-get update; 
sudo apt-get install aziot-edge