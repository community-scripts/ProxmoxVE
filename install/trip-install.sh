#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/itskovacs/TRIP

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "trip" "itskovacs/TRIP"

msg_info "Building Frontend"
cd /opt/trip/src
$STD npm install
$STD npm run build
msg_ok "Built Frontend"

msg_info "Setting up Backend"
cd /opt/trip/backend
$STD uv venv /opt/trip/.venv
$STD uv pip install --python /opt/trip/.venv/bin/python -r trip/requirements.txt
msg_ok "Set up Backend"

msg_info "Configuring Application"
mkdir -p /opt/trip/frontend
cp -r /opt/trip/src/dist/trip/browser/* /opt/trip/frontend/
mkdir -p /opt/trip_storage/{attachments,backups,assets}

cat <<EOF >/opt/trip.env
# TRIP Configuration
# https://itskovacs.github.io/trip/docs/getting-started/configuration/
ATTACHMENTS_FOLDER=/opt/trip_storage/attachments
BACKUPS_FOLDER=/opt/trip_storage/backups
ASSETS_FOLDER=/opt/trip_storage/assets
FRONTEND_FOLDER=/opt/trip/frontend
SQLITE_FILE=/opt/trip_storage/trip.sqlite
EOF
msg_ok "Configured Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/trip.service
[Unit]
Description=TRIP - Minimalist POI Map Tracker and Trip Planner
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/trip/backend
EnvironmentFile=/opt/trip.env
ExecStart=/opt/trip/.venv/bin/fastapi run /opt/trip/backend/trip/main.py --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now trip
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
