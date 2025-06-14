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
$STD apt-get install -y \
  build-essential \
  make \
  libpq-dev \
  ca-certificates
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Spoolman"
RELEASE=$(curl -fsSL https://github.com/Donkie/Spoolman/releases/latest | grep "title>Release" | cut -d " " -f 4)
cd /opt
curl -fsSL "https://github.com/Donkie/Spoolman/releases/download/$RELEASE/spoolman.zip" -o "spoolman.zip"
$STD unzip spoolman.zip -d spoolman
rm -f spoolman.zip
cd spoolman
$STD uv venv /opt/spoolman/.venv
$STD uv pip install -r requirements.txt

curl -fsSL "https://raw.githubusercontent.com/Donkie/Spoolman/master/.env.example" -o ".env"
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Spoolman"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/spoolman.service
[Unit]
Description=Spoolman
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/spoolman
EnvironmentFile=/opt/spoolman/.env
ExecStart=/opt/spoolman/.venv/bin/uvicorn spoolman.main:app --host 0.0.0.0 --port 7912
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spoolman
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
