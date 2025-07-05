#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "bytestash" "jordan-dalby/ByteStash"

msg_info "Installing ByteStash"
JWT_SECRET=$(openssl rand -base64 32 | tr -d '/+=')
cd /opt/bytestash/server
$STD npm install
cd /opt/bytestash/client
$STD npm install
msg_ok "Installed ByteStash"

read -rp "${TAB3}Do you want to allow registration of multiple accounts? [y/n]: " allowreg

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bytestash-backend.service
[Unit]
Description=ByteStash Backend Service
After=network.target

[Service]
WorkingDirectory=/opt/bytestash/server
ExecStart=/usr/bin/node src/app.js
Restart=always
Environment=JWT_SECRET=$JWT_SECRET

[Install]
WantedBy=multi-user.target
EOF

if [[ "$allowreg" =~ ^[Yy]$ ]]; then
  sed -i '8i\Environment=ALLOW_NEW_ACCOUNTS=true' /etc/systemd/system/bytestash-backend.service
fi

cat <<EOF >/etc/systemd/system/bytestash-frontend.service
[Unit]
Description=ByteStash Frontend Service
After=network.target bytestash-backend.service

[Service]
WorkingDirectory=/opt/bytestash/client
ExecStart=/usr/bin/npx vite --host
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now bytestash-backend
systemctl enable -q --now bytestash-frontend
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
