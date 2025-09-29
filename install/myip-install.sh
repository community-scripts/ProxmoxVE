#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ipcheck.ing/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "myip" "jason5ng32/MyIP" "tarball"

msg_info "Configuring MyIP"
cd /opt/myip
cp .env.example .env
$STD npm install
$STD npm run build
msg_ok "Configured MyIP"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/myip.service
[Unit]
Description=MyIP Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/myip
ExecStart=/usr/bin/npm start
EnvironmentFile=/opt/myip/.env
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myip
msg_ok "Service created"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
