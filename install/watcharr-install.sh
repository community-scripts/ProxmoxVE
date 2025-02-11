#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sbondCo/Watcharr

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
  gcc \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setup Golang"
set +o pipefail
temp_file=$(mktemp)
golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
tar -C /usr/local -xzf "$temp_file"
ln -sf /usr/local/go/bin/go /usr/local/bin/go
rm -f "$temp_file"
set -o pipefail
msg_ok "Setup Golang"

msg_info "Setup Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Setup Watcharr"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/sbondCo/Watcharr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/sbondCo/Watcharr/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
tar -xzf "$temp_file"
mv Watcharr-${RELEASE}/ /opt/watcharr
cd /opt/watcharr
$STD npm i
$STD npm run build
mv ./build ./server/ui
cd server
export CGO_ENABLED=1 GOOS=linux
go mod download
go build -o ./watcharr
cat <<EOF >/opt/start.sh
#! /bin/bash
source ~/.bashrc
cd /opt/watcharr/server
./watcharr
EOF
chmod +x /opt/start.sh
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
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
systemctl enable -q --now watcharr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"