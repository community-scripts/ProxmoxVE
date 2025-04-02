#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lidarr.audio/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sqlite3 \
  libchromaprint-tools \
  mediainfo
msg_ok "Installed Dependencies"

msg_info "Installing Lidarr"
temp_file="$(mktemp)"
mkdir -p /var/lib/lidarr/
chmod 775 /var/lib/lidarr/
RELEASE=$(curl -fsSL https://api.github.com/repos/Lidarr/Lidarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/Lidarr/Lidarr/releases/download/v${RELEASE}/Lidarr.master.${RELEASE}.linux-core-x64.tar.gz" -o "$temp_file"
$STD tar -xvzf "$temp_file"
mv Lidarr /opt
chmod 775 /opt/Lidarr
msg_ok "Installed Lidarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lidarr.service
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/var/lib/lidarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now lidarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
