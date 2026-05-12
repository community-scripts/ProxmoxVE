#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hudikhq/hoodik

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "hoodik" "hudikhq/hoodik" "prebuild" "latest" "/opt/hoodik" "*x86_64.tar.gz"

msg_info "Configuring Hoodik"
mkdir -p /opt/hoodik_data
JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
cat <<EOF >/opt/hoodik/.env
DATA_DIR=/opt/hoodik_data
HTTP_PORT=5443
HTTP_ADDRESS=0.0.0.0
JWT_SECRET=${JWT_SECRET}
APP_URL=http://${LOCAL_IP}:5443
SSL_DISABLED=true
COOKIE_SECURE=false
COOKIE_HTTP_ONLY=false
MAILER_TYPE=none
RUST_LOG=hoodik=info,error=info
EOF
msg_ok "Configured Hoodik"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hoodik.service
[Unit]
Description=Hoodik - Encrypted File Storage
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hoodik_data
EnvironmentFile=/opt/hoodik/.env
ExecStart=/opt/hoodik/hoodik
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hoodik
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
