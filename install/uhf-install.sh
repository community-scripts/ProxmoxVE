#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: zackwithak13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.uhfapp.com/server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Setting Up UHF Server Environment"
mkdir -p /etc/uhf-server
mkdir -p /var/lib/uhf-server/data
mkdir -p /var/lib/uhf-server/recordings
cat <<EOF >/etc/uhf-server/.env
API_HOST=0.0.0.0
API_PORT=7568
RECORDINGS_DIR=/var/lib/uhf-server/recordings
DB_PATH=/var/lib/uhf-server/data/db.json
LOG_LEVEL=INFO
EOF
msg_ok "Set Up UHF Server Environment"

fetch_and_deploy_gh_release "comskip" "swapplications/comskip" "prebuild" "latest" "/opt/comskip" "comskip-x64-*.zip"
fetch_and_deploy_gh_release "uhf-server" "swapplications/uhf-server-dist" "prebuild" "latest" "/opt/uhf-server" "UHF.Server-linux-x64-*.zip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/uhf-server.service
[Unit]
Description=UHF Server service
After=syslog.target network-online.target
[Service]
Type=simple
WorkingDirectory=/opt/uhf-server
EnvironmentFile=/etc/uhf-server/.env
ExecStart=/opt/uhf-server/uhf-server
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now uhf-server
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
