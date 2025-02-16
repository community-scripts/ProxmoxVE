#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Suwayomi/Suwayomi-Server

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
  openjdk-17-jre \
  libc++-dev
msg_ok "Installed Dependencies"

msg_info "Settting up Suwayomi-Server"
URL=$(curl -s https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest | grep "browser_download_url" | awk '{print substr($2, 2, length($2)-2) }' |  tail -n+2 | head -n 1)
RELEASE=$(curl -s https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q $URL
$STD dpkg -i *.deb
echo ${RELEASE} >/opt/suwayomi-server_version.txt
msg_ok "Done setting up Suwayomi-Server"
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/suwayomi-server.service
[Unit]
Description=Suwayomi-Server Service
After=network.target

[Service]
ExecStart=/usr/bin/suwayomi-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now suwayomi-server
msg_ok "Created Service"
motd_ssh
customize
msg_info "Cleaning up"
rm -f *.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
