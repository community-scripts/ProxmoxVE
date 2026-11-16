#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/decolua/9router

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
setup_ffmpeg

msg_info "Installing 9Router"
$STD npm install -g --ignore-scripts "9router@${var_appversion:-latest}"
msg_ok "Installed 9Router"

msg_info "Configuring 9Router"
mkdir -p /opt/9router_data
cat <<EOF >/opt/9router_data/.env
DATA_DIR=/opt/9router_data
PORT=20128
HOSTNAME=0.0.0.0
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
BASE_URL=http://localhost:20128
INITIAL_PASSWORD=$(random_password)
JWT_SECRET=$(openssl rand -hex 32)
API_KEY_SECRET=$(openssl rand -hex 32)
MACHINE_ID_SALT=$(openssl rand -hex 16)
EOF
chmod 600 /opt/9router_data/.env
msg_ok "Configured 9Router"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/9router.service
[Unit]
Description=9Router
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/usr/lib/node_modules/9router/app
EnvironmentFile=/opt/9router_data/.env
ExecStart=/usr/bin/node /usr/lib/node_modules/9router/app/custom-server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now 9router
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
