#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "tracktor" "javedh-dev/tracktor" "tarball" "latest" "/opt/tracktor"

msg_info "Configuring Tracktor"
cd /opt/tracktor
$STD npm install
$STD npm run build
mkdir -p /opt/tracktor-data/{uploads,logs}
cat <<EOF >/opt/tracktor.env
NODE_ENV=production
# Set this to the path of the database file. Default - ./tracktor.db
DB_PATH=/opt/tracktor-data/tracktor.db
# Set this to the path of the uploads directory. Default - ./uploads
UPLOADS_DIR="/opt/tracktor-data/uploads"
# Set this to the path of the logs directory. Default - ./logs
LOG_DIR="/opt/tracktor-data/logs"
# Hostname to bind the server to. Default - 0.0.0.0
#HOST="0.0.0.0"
# Port to bind the server to. Default - 3000
#PORT=3000
# Set this to remove upload size limitations. Default - 512 Kb
BODY_SIZE_LIMIT=Infinity
# Enable request logging. Default - true
#LOG_REQUESTS=true
# Set the logging level. Options - error, warn, info, verbose, debug, silly. Default - info
#LOG_LEVEL="info"
# Enable demo mode. Default - false
#TRACKTOR_DEMO_MODE=false
# Force reseeding of data on every startup. Default - false
#FORCE_DATA_SEED=false
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
cleanup_lxc
