#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Nezreka/SoulSync

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  gcc \
  libffi-dev \
  libssl-dev \
  libchromaprint-tools \
  ffmpeg
msg_ok "Installed Dependencies"

UV_PYTHON="3.11" setup_uv

fetch_and_deploy_gh_release "soulsync" "Nezreka/SoulSync" "tarball"

msg_info "Setting up Application"
cd /opt/soulsync
$STD uv venv /opt/soulsync/.venv --python 3.11
$STD uv pip install -r requirements.txt --python /opt/soulsync/.venv/bin/python
mkdir -p /opt/soulsync/{config,data,logs}
msg_ok "Set up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/soulsync.service
[Unit]
Description=SoulSync Music Discovery
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/soulsync
ExecStart=/opt/soulsync/.venv/bin/python web_server.py
Environment=PYTHONPATH=/opt/soulsync PYTHONUNBUFFERED=1 DATABASE_PATH=/opt/soulsync/data/music_library.db
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now soulsync
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
