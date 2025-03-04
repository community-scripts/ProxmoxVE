#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

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
  tini \
  gpg \
  build-essential
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install --global yarn
msg_ok "Installed Node.js"

msg_info "Installing Actual Budget"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/actualbudget/actual/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/actualbudget/actual/archive/refs/tags/v${RELEASE}.tar.gz
tar -xzf v${RELEASE}.tar.gz
mv actual-${RELEASE} /opt/actualbudget

mkdir -p /opt/actualbudget-data/{server-files,upload,migrate,user-files,migrations,config}
chown -R root:root /opt/actualbudget-data
chmod -R 755 /opt/actualbudget-data

cat <<EOF > /opt/actualbudget-data/.env
ACTUAL_UPLOAD_DIR=/opt/actualbudget-data/upload
ACTUAL_DATA_DIR=/opt/actualbudget-data
ACTUAL_SERVER_FILES_DIR=/opt/actualbudget-data/server-files
ACTUAL_USER_FILES=/opt/actualbudget-data/user-files
PORT=5006
ACTUAL_TRUSTED_PROXIES="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.1/32,::1/128,fc00::/7"
ACTUAL_HTTPS_KEY=/opt/actualbudget/selfhost.key
ACTUAL_HTTPS_CERT=/opt/actualbudget/selfhost.crt
EOF
cd /opt/actualbudget
$STD yarn workspaces focus @actual-app/sync-server --production
$STD openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout selfhost.key -out selfhost.crt <<EOF
US
California
San Francisco
My Organization
My Unit
localhost
myemail@example.com
EOF
echo "${RELEASE}" >"/opt/actualbudget_version.txt"
msg_ok "Installed Actual Budget"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/actualbudget.service
[Unit]
Description=Actual Budget Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/actualbudget
EnvironmentFile=/opt/actualbudget-data/.env
ExecStart=/usr/bin/yarn start:server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now actualbudget
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
