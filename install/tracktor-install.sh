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
mkdir /opt/tracktor-data
HOST_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/opt/tracktor/app/backend/.env
NODE_ENV=production
PUBLIC_DEMO_MODE=false
DB_PATH=/opt/tracktor-data/tracktor.db
# Replace this URL if using behind reverse proxy for https traffic. Though it is optional and should work without changing
PUBLIC_API_BASE_URL=http://$HOST_IP:3000
# Here add the reverse proxy url as well to avoid cross errors from the app. 
CORS_ORIGINS=http://$HOST_IP:3000 
PORT=3000
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
EnvironmentFile=/opt/tracktor/app/backend/.env
ExecStart=/usr/bin/npm start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tracktor
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
