#!/bin/bash

echo "==============================="
echo " GitHub Actions Runner Installer"
echo "==============================="

# Ask required inputs
read -p "Enter GitHub Organization/User Name: " ORG
read -p "Enter Repository Name: " REPO
read -p "Enter GitHub PAT Token: " TOKEN
read -p "Enter Linux username to run the runner (ubuntu/azureuser/ec2-user etc): " LINUX_USER

RUNNER_DIR="/home/$LINUX_USER/actions-runner"

# Create folder
sudo mkdir -p $RUNNER_DIR
sudo chown -R $LINUX_USER:$LINUX_USER $RUNNER_DIR
cd $RUNNER_DIR

# Download latest runner
LATEST_RUNNER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep browser_download_url | grep linux-x64 | cut -d '"' -f 4)

echo "Downloading $LATEST_RUNNER ..."
curl -L -o actions-runner-linux-x64.tar.gz $LATEST_RUNNER

# Extract runner
tar xzf actions-runner-linux-x64.tar.gz

# Configure runner
sudo -u $LINUX_USER ./config.sh --url https://github.com/$ORG/$REPO --token $TOKEN

# Create systemd service file
cat <<EOF | sudo tee /etc/systemd/system/github-runner.service
[Unit]
Description=GitHub Actions Self-Hosted Runner
After=network.target

[Service]
ExecStart=$RUNNER_DIR/run.sh
WorkingDirectory=$RUNNER_DIR
User=$LINUX_USER
Restart=always
RestartSec=5
Environment=PATH=/usr/bin:/usr/local/bin

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable github-runner
sudo systemctl start github-runner

echo "==============================="
echo "✅ GitHub Runner Installed & Started"
echo "✅ Auto-start on reboot enabled"
echo "✅ Running as user: $LINUX_USER"
echo "==============================="

sudo systemctl status github-runner --no-pager
