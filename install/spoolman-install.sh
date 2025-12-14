#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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
  libpq-dev
msg_ok "Installed Dependencies"

msg_info "Setting up Python3"
$STD apt install -y \
  python3-dev \
  python3-setuptools \
  python3-wheel \
  python3-pip
msg_ok "Setup Python3"

fetch_and_deploy_gh_release "spoolman" "Donkie/Spoolman" "prebuild" "latest" "/opt/spoolman" "spoolman.zip"

msg_info "Setting up Spoolman"
cd /opt/spoolman
$STD pip3 install --upgrade --ignore-installed -r requirements.txt
cp .env.example .env
msg_ok "Setup Spoolman"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/spoolman.service
[Unit]
Description=Spoolman
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/spoolman
EnvironmentFile=/opt/spoolman/.env
ExecStart=uvicorn spoolman.main:app --host "${SPOOLMAN_HOST}" --port "${SPOOLMAN_PORT}"
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
