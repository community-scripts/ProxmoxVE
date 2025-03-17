#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://triliumnext.github.io/Docs/

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
  mc
msg_ok "Installed Dependencies"

msg_info "Setup TriliumNext"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/TriliumNext/Notes/releases/download/v${RELEASE}/TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz
tar -xf TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz
mv TriliumNextNotes-Server-$RELEASE-linux-x64 /opt/trilium
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup TriliumNext"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/trilium.service
[Unit]
Description=Trilium Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=/opt/trilium/trilium.sh
WorkingDirectory=/opt/trilium/
TimeoutStopSec=20
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q trilium
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/TriliumNextNotes-Server-${RELEASE}-linux-x64.tar.xz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
