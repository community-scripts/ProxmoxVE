#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Donkie/Spoolman

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libpq-dev \
  libffi-dev
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "spoolman" "Donkie/Spoolman" "prebuild" "latest" "/opt/spoolman" "spoolman.zip"
PYTHON_VERSION="3.14" setup_uv

msg_info "Setting up Spoolman"
cd /opt/spoolman
$STD uv sync --locked --no-install-project
$STD uv sync --locked
cp .env.example .env
msg_ok "Setup Spoolman"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/spoolman.service
[Unit]
Description=Spoolman
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/spoolman
EnvironmentFile=/opt/spoolman/.env
ExecStart=/usr/bin/bash /opt/spoolman/scripts/start.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spoolman
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
