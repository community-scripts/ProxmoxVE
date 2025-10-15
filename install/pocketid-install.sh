#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pocket-id/pocket-id

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -r -p "${TAB3}What public URL do you want to use (e.g. pocketid.mydomain.com)? " public_url
fetch_and_deploy_gh_release "pocket-id" "pocket-id/pocket-id" "singlefile" "latest" "/opt/pocket-id/" "pocket-id-linux-amd64"

msg_info "Configuring Pocket ID"
cat <<EOF >/opt/pocket-id/.env
APP_ENV=production
APP_URL=https://${public_url}
TRUST_PROXY=false
# MAXMIND_LICENSE_KEY=
PORT=1411
HOST=0.0.0.0
EOF
msg_ok "Configured Pocket ID"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pocketid.service
[Unit]
Description=Pocket ID Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/pocket-id
EnvironmentFile=/opt/pocket-id/.env
ExecStart=/opt/pocket-id/pocket-id
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"

msg_info "Starting Service"
systemctl enable -q --now pocketid
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
