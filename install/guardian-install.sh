#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: HydroshieldMKII
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HydroshieldMKII/Guardian

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sqlite3
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "guardian" "HydroshieldMKII/Guardian" "tarball" "latest" "/opt/guardian"

msg_info "Configuring ${APPLICATION}"
cd /opt/guardian/backend
$STD npm ci
$STD npm run build
cd /opt/guardian/frontend
$STD npm ci
export DEPLOYMENT_MODE=standalone
$STD npm run build
msg_ok "Configured ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/guardian-backend.service
[Unit]
Description=Guardian Backend
After=network.target

[Service]
WorkingDirectory=/opt/guardian/backend
ExecStart=/usr/bin/node dist/main.js
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/guardian-frontend.service
[Unit]
Description=Guardian Frontend
After=guardian-backend.service network.target
Wants=guardian-backend.service

[Service]
WorkingDirectory=/opt/guardian/frontend
Environment=DEPLOYMENT_MODE=standalone
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now guardian-backend
systemctl enable -q --now guardian-frontend
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
