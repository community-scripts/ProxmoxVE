#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  make \
  g++
msg_ok "Installed Dependencies"

msg_info "Installing Actual Budget"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/actualbudget/actual/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
NODE_VERSION="22"
setup_nodejs
mkdir -p /opt/actualbudget-data/{server-files,upload,migrate,user-files,migrations,config}
chown -R root:root /opt/actualbudget-data
chmod -R 755 /opt/actualbudget-data

cat <<EOF >/opt/actualbudget-data/config.json
{
  "port": 5006,
  "hostname": "::",
  "serverFiles": "/opt/actualbudget-data/server-files",
  "userFiles": "/opt/actualbudget-data/user-files",
  "trustedProxies": [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "127.0.0.0/8",
    "::1/128",
    "fc00::/7"
  ],
  "https": {
    "key": "/opt/actualbudget/selfhost.key",
    "cert": "/opt/actualbudget/selfhost.crt"
  }
}
EOF

mkdir -p /opt/actualbudget
cd /opt/actualbudget
$STD npm install --location=global @actual-app/sync-server
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
Environment=ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB=20
Environment=ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB=50
Environment=ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB=20
ExecStart=/usr/bin/actual-server --config /opt/actualbudget-data/config.json
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
