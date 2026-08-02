#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/daya0576/beaverhabits

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.14" setup_uv

fetch_and_deploy_gh_release "beaverhabits" "daya0576/beaverhabits" "tarball"

msg_info "Installing Dependencies"
cd /opt/beaverhabits
$STD uv sync --no-dev
msg_ok "Installed Dependencies"

msg_info "Configuring BeaverHabits"
mkdir -p /opt/beaverhabits/.user
msg_ok "Configured BeaverHabits"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/beaverhabits.service
[Unit]
Description=BeaverHabits Habit Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/beaverhabits
Environment=HABITS_STORAGE=USER_DISK
Environment=NICEGUI_STORAGE_PATH=/opt/beaverhabits/.user/.nicegui
ExecStart=/opt/beaverhabits/.venv/bin/gunicorn beaverhabits.main:app --bind 0.0.0.0:8080 -w 1 -k uvicorn_worker.UvicornWorker --max-requests 10000 --log-level info
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now beaverhabits
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
