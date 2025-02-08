#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sbondCo/Watcharr

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gcc
wget -q https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash &> /dev/null
tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc
$STD nvm install node
export CGO_ENABLED=1
msg_ok "Installed Dependencies"

msg_info "Setting up Watcharr. Patience"
RELEASE=$(curl -s https://api.github.com/repos/sbondCo/Watcharr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/sbondCo/Watcharr/archive/refs/tags/v${RELEASE}.tar.gz"
tar -xzf v${RELEASE}.tar.gz
mv Watcharr-${RELEASE}/ /opt/watcharr
cd /opt/watcharr
$STD npm i
$STD npm run build
mv ./build ./server/ui
cd server
go mod download
GOOS=linux go build -o ./watcharr
cat <<EOF >/opt/start.sh
#! /bin/bash
source ~/.bashrc
cd /opt/watcharr/server
./watcharr
EOF
chmod +x /opt/start.sh
echo "${RELEASE}" >/opt/watcharr_version.txt
msg_ok "Setup Watcharr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/watcharr.service
[Unit]
Description=Watcharr Service
After=network.target

[Service]
WorkingDirectory=/opt/watcharr/server
ExecStart=/opt/start.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now watcharr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f ~/*.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"