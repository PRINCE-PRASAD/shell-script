#!/bin/bash

set -e

echo "🔹 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🔹 Installing dependencies..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "🔹 Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "🔹 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "🔹 Installing Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🔹 Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "🔹 Adding current user to docker group..."
sudo usermod -aG docker $USER

echo "✅ Docker installation completed!"
echo "⚠️ Logout & login again or reboot to use docker without sudo."
