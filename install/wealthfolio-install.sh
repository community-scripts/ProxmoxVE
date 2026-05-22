#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wealthfolio.app/ | Github: https://github.com/wealthfolio/wealthfolio

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y argon2
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "wealthfolio" "wealthfolio/wealthfolio" "prebuild" "latest" "/opt/wealthfolio" "wealthfolio-server-*-linux-amd64.tar.gz"

msg_info "Installing Wealthfolio"
install -m 755 /opt/wealthfolio/wealthfolio-server /usr/local/bin/wealthfolio-server
msg_ok "Installed Wealthfolio"

msg_info "Configuring Wealthfolio"
mkdir -p /opt/wealthfolio_data
SECRET_KEY=$(openssl rand -base64 32)
WF_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-16)
WF_PASSWORD_HASH=$(echo -n "$WF_PASSWORD" | argon2 "$(openssl rand -base64 16)" -id -e)
cat <<EOF >/opt/wealthfolio/.env
WF_LISTEN_ADDR=0.0.0.0:8080
WF_DB_PATH=/opt/wealthfolio_data/wealthfolio.db
WF_SECRET_KEY=${SECRET_KEY}
WF_AUTH_PASSWORD_HASH=${WF_PASSWORD_HASH}
WF_STATIC_DIR=/opt/wealthfolio/dist
WF_REQUEST_TIMEOUT_MS=30000
WF_CORS_ALLOW_ORIGINS=http://${LOCAL_IP}:8080
EOF
echo "WF_PASSWORD=${WF_PASSWORD}" >~/wealthfolio.creds
msg_ok "Configured Wealthfolio"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wealthfolio.service
[Unit]
Description=Wealthfolio Investment Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wealthfolio
EnvironmentFile=/opt/wealthfolio/.env
ExecStart=/usr/local/bin/wealthfolio-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wealthfolio
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
