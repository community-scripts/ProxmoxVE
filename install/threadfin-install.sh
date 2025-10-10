#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Threadfin/Threadfin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ffmpeg \
  vlc
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "threadfin" "threadfin/threadfin" "singlefile" "latest" "/opt/threadfin" "Threadfin_linux_amd64"
mv /root/.threadfin /root/.threadfin_version
mkdir -p /root/.threadfin

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/threadfin.service
[Unit]
Description=Threadfin: M3U Proxy for Plex DVR and Emby/Jellyfin Live TV
After=syslog.target network.target
[Service]
Type=simple
WorkingDirectory=/opt/threadfin
ExecStart=/opt/threadfin/threadfin
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now threadfin
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
