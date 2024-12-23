#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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

msg_info "Installing Dependencies (patience)"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing Navidrome"
RELEASE=$(curl -s https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
install -d -o root -g root /opt/navidrome
install -d -o root -g root /var/lib/navidrome
wget -q https://github.com/navidrome/navidrome/releases/download/v${RELEASE}/navidrome_${RELEASE}_linux_amd64.tar.gz -O Navidrome.tar.gz
$STD tar -xvzf Navidrome.tar.gz -C /opt/navidrome/
chown -R root:root /opt/navidrome
chmod +x /opt/navidrome/navidrome
mkdir -p /music
cat <<EOF >/var/lib/navidrome/navidrome.toml
MusicFolder = '/music'
EOF
msg_ok "Installed Navidrome"

msg_info "Creating Service"
service_path="/etc/systemd/system/navidrome.service"

echo "[Unit]
Description=Navidrome Music Server and Streamer compatible with Subsonic/Airsonic
After=remote-fs.target network.target
AssertPathExists=/var/lib/navidrome

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/navidrome/navidrome --configfile '/var/lib/navidrome/navidrome.toml'
WorkingDirectory=/var/lib/navidrome
TimeoutStopSec=20
KillMode=process
Restart=on-failure
DevicePolicy=closed
NoNewPrivileges=yes
PrivateTmp=yes
PrivateUsers=yes
ProtectControlGroups=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictNamespaces=yes
RestrictRealtime=yes
SystemCallFilter=~@clock @debug @module @mount @obsolete @reboot @setuid @swap
ReadWritePaths=/var/lib/navidrome
ProtectSystem=full

[Install]
WantedBy=multi-user.target" >$service_path
systemctl daemon-reload
$STD systemctl enable --now navidrome.service

msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf /root/Navidrome.tar.gz
msg_ok "Cleaned"
