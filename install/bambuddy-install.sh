#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Adrian-RDA
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maziggy/bambuddy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y libglib2.0-0 ffmpeg
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "bambuddy" "maziggy/bambuddy" "tarball" "latest" "/opt/bambuddy"

msg_info "Setting up Python Environment"
cd /opt/bambuddy
$STD uv venv
$STD uv pip install -r requirements.txt
msg_ok "Set up Python Environment"

msg_info "Building Frontend"
cd /opt/bambuddy/frontend
$STD npm install
$STD npm run build
msg_ok "Built Frontend"

msg_info "Configuring Bambuddy"
mkdir -p /opt/bambuddy/data /opt/bambuddy/logs
cat <<EOF >/opt/bambuddy/.env
DEBUG=false
LOG_LEVEL=INFO
LOG_TO_FILE=true
EOF
msg_ok "Configured Bambuddy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bambuddy.service
[Unit]
Description=Bambuddy - Bambu Lab Print Management
Documentation=https://github.com/maziggy/bambuddy
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bambuddy
ExecStart=/opt/bambuddy/.venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bambuddy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
