#!/usr/bin/env bash

# Copyright (c) 2025 Community Scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tracktor.bytedge.in

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_nodejs
fetch_and_deploy_gh_release "tracktor" "javedh-dev/tracktor" "tarball" "latest" "/opt/tracktor"

msg_info "Configuring Tracktor"
cd /opt/tracktor
$STD npm install
$STD npm run build
mkdir -p /opt/tracktor-data/{uploads,logs}
HOST_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/opt/tracktor.env
NODE_ENV=production
DB_PATH=/opt/tracktor-data/tracktor.db
UPLOADS_DIR="/opt/tracktor-data/uploads"
LOG_DIR="/opt/tracktor-data/logs"
# If server host is not set by default it will run on all interfaces - 0.0.0.0
# SERVER_HOST="" 
SERVER_PORT=3000
PORT=3000
# Set this if you want to secure your endpoints otherwise default will be "*"
# CORS_ORIGINS="*"
# Set this if you are using backend and frontend separately. For lxc installation this is not needed
# PUBLIC_API_BASE_URL=""
LOG_REQUESTS=true
LOG_LEVEL="info"
AUTH_PIN=123456
# PUBLIC_DEMO_MODE=false
# FORCE_DATA_SEED=false
EOF
msg_ok "Configured Tracktor"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/tracktor.service
[Unit]
Description=Tracktor Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/tracktor
EnvironmentFile=/opt/tracktor.env
ExecStart=/usr/bin/npm start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tracktor
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
