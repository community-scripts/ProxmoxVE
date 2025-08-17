#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/StarFleetCPTN/GoMFT

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sqlite3 \
  rclone \
  tzdata \
  ca-certificates
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "gomft" "StarFleetCPTN/GoMFT" "singlefile" "latest" "/opt/gomft" "gomft*linux-amd64"

msg_info "Configuring ${APPLICATION}"
JWT_SECRET_KEY=$(openssl rand -base64 24 | tr -d '/+=')
cat <<EOF >/opt/gomft/.env
SERVER_ADDRESS=:8080
DATA_DIR=/opt/gomft/data/gomft
BACKUP_DIR=/opt/gomft/data/gomft/backups
JWT_SECRET=$JWT_SECRET_KEY
BASE_URL=http://localhost:8080

# Email configuration
EMAIL_ENABLED=false
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_FROM_EMAIL=gomft@example.com
EMAIL_FROM_NAME=GoMFT
EMAIL_REPLY_TO=
EMAIL_ENABLE_TLS=true
EMAIL_REQUIRE_AUTH=true
EMAIL_USERNAME=smtp_username
EMAIL_PASSWORD=smtp_password
EOF
msg_ok "Configured ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gomft.service
[Unit]
Description=GoMFT Service
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/opt/gomft/.env
WorkingDirectory=/opt/gomft
ExecStart=/opt/gomft/gomft
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gomft
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
