#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
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
  curl \
  sudo \
  make \
  libpq-dev \
  gpg \
  ca-certificates \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Python3"
$STD apt-get install -y \
  python3-dev \
  python3-setuptools \
  python3-wheel \
  python3-pip
msg_ok "Installed Python3"

msg_info "Installing Spoolman"
RELEASE=$(wget -q https://github.com/Donkie/Spoolman/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
cd /opt
wget -q https://github.com/Donkie/Spoolman/releases/download/$RELEASE/spoolman.zip
unzip -q spoolman.zip -d spoolman
rm -rf spoolman.zip
cd spoolman
$STD pip3 install -r requirements.txt
wget -q https://raw.githubusercontent.com/Donkie/Spoolman/master/.env.example -O .env
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
ExecStart=uvicorn spoolman.main:app --host 0.0.0.0 --port 7912
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spoolman.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
