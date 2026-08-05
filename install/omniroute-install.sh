#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/diegosouzapw/OmniRoute

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="26" setup_nodejs

msg_info "Installing OmniRoute"
$STD npm install -g omniroute@latest
msg_ok "Installed OmniRoute"

msg_info "Configuring OmniRoute"
mkdir -p /opt/omniroute
cat <<EOF >/opt/omniroute/.env
JWT_SECRET=$(openssl rand -base64 48)
API_KEY_SECRET=$(openssl rand -hex 32)
STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 32)
STORAGE_ENCRYPTION_KEY_VERSION=v1
INITIAL_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-20)
PORT=20128
OMNIROUTE_SERVER_HOST=0.0.0.0
EOF
chmod 600 /opt/omniroute/.env
msg_ok "Configured OmniRoute"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/omniroute.service
[Unit]
Description=OmniRoute AI Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/omniroute
Environment=DATA_DIR=/opt/omniroute
ExecStart=/usr/bin/omniroute
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now omniroute
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
