#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.qbittorrent.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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
  mc
msg_ok "Installed Dependencies"

msg_info "Setup qBittorrent-nox"
FULLRELEASE=$(curl -s https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
RELEASE=$(echo $FULLRELEASE | cut -c 9-13)
mkdir -p /opt/qbittorrent
curl -fsSL "https://github.com/userdocs/qbittorrent-nox-static/releases/download/${FULLRELEASE}/x86_64-qbittorrent-nox" -o /opt/qbittorrent/qbittorrent-nox
chmod +x /opt/qbittorrent/qbittorrent-nox
mkdir -p $HOME/.config/qBittorrent/
cat <<EOF >$HOME/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Password_PBKDF2="@ByteArray(amjeuVrF3xRbgzqWQmes5A==:XK3/Ra9jUmqUc4RwzCtrhrkQIcYczBl90DJw2rT8DFVTss4nxpoRhvyxhCf87ahVE3SzD8K9lyPdpyUCfmVsUg==)"
WebUI\Port=8090
WebUI\UseUPnP=false
WebUI\Username=admin
EOF
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup qBittorrent-nox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/qbittorrent-nox.service
[Unit]
Description=qBittorrent client
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/qbittorrent/qbittorrent-nox
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now qbittorrent-nox
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
