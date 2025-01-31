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
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing MediaMTX"
RELEASE=$(curl -s https://api.github.com/repos/bluenviron/mediamtx/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
mkdir -p /opt/mediamtx
cd /opt/mediamtx
wget -q https://github.com/bluenviron/mediamtx/releases/download/${RELEASE}/mediamtx_${RELEASE}_linux_amd64.tar.gz
tar xzf mediamtx_${RELEASE}_linux_amd64.tar.gz
rm -rf mediamtx_${RELEASE}_linux_amd64.tar.gz
msg_ok "Installed MediaMTX"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mediamtx.service
[Unit]
Description=MediaMTX
After=syslog.target network-online.target

[Service]
ExecStart=/opt/mediamtx/./mediamtx
WorkingDirectory=/opt/mediamtx
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mediamtx.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
