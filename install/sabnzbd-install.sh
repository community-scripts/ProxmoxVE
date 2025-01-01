#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y par2
$STD apt-get install -y p7zip-full
cat <<EOF >/etc/apt/sources.list.d/non-free.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF
$STD apt-get update
$STD apt-get install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y \
  python3-dev \
  python3-pip
$STD apt-get install -y python3-setuptools
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Installing SABnzbd"
RELEASE=$(curl -s https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
$STD tar zxvf <(curl -fsSL https://github.com/sabnzbd/sabnzbd/releases/download/$RELEASE/SABnzbd-${RELEASE}-src.tar.gz)
mv SABnzbd-${RELEASE} /opt/sabnzbd
cd /opt/sabnzbd
$STD python3 -m pip install -r requirements.txt
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed SABnzbd"

msg_info "Creating Service"
service_path="/etc/systemd/system/sabnzbd.service"
echo "[Unit]
Description=SABnzbd
After=network.target
[Service]
WorkingDirectory=/opt/sabnzbd
ExecStart=python3 SABnzbd.py -s 0.0.0.0:7777
Restart=always
User=root
[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q sabnzbd.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
