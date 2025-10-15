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
$STD apt install -y \
  sqlite3 \
  libchromaprint-tools \
  mediainfo
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "lidarr" "Lidarr/Lidarr" "prebuild" "latest" "/opt/Lidarr" "Lidarr.master*linux-core-x64.tar.gz"

msg_info "Configuring Lidarr"
mkdir -p /var/lib/lidarr/
chmod 775 /var/lib/lidarr/
chmod 775 /opt/Lidarr
msg_ok "Configured Lidarr"

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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
