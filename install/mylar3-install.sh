#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: davalanche
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mylar3/mylar3

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  python3-pip
echo "deb http://deb.debian.org/debian bookworm non-free non-free-firmware" > /etc/apt/sources.list.d/non-free.list
$STD apt-get update
$STD apt-get install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Installed Dependencies"

msg_info "Installing ${APPLICATION}"
mkdir -p /opt/mylar3
mkdir -p /opt/mylar3-data
$STD git clone -b master https://github.com/mylar3/mylar3.git /opt/mylar3
$STD pip install -U --no-cache-dir pip
$STD pip install --no-cache-dir -r /opt/mylar3/requirements.txt
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mylar3.service
[Unit]
Description=Mylar3 Service
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/mylar3/Mylar.py --daemon --nolaunch --datadir=/opt/mylar3-data
GuessMainPID=no
Type=forking
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mylar3.service
msg_ok "Created Service"

msg_info "Updating ${APPLICATION} configuration"
# version detection and updates through the user interface do not currently work unless "check_github_on_startup = True"
sed -i -e 's/check_github_on_startup = False/check_github_on_startup = True/' -e 's/check_github = False/check_github = True/' /opt/mylar3-data/config.ini
systemctl restart mylar3
msg_ok "${APPLICATION} configuration updated"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
