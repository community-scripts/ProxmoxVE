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
  jq
echo "deb http://deb.debian.org/debian bookworm non-free non-free-firmware" > /etc/apt/sources.list.d/non-free.list
$STD apt-get update
$STD apt-get install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD pip install -U --no-cache-dir pip
msg_ok "Updated Python3"

msg_info "Installing ${APPLICATION}"
mkdir -p /opt/mylar3
mkdir -p /opt/mylar3-data
RELEASE=$(curl -s https://api.github.com/repos/mylar3/mylar3/releases/latest | jq -r '.tag_name')
wget -qO- https://github.com/mylar3/mylar3/archive/refs/tags/${RELEASE}.tar.gz | tar -xz --strip-components=1 -C /opt/mylar3
$STD pip install --no-cache-dir -r /opt/mylar3/requirements.txt
echo "${RELEASE}" > /opt/${APPLICATION}_version.txt
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

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
