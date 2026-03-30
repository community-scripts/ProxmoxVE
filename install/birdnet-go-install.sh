#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tphakala/birdnet-go

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libasound2 \
  sox \
  alsa-utils \
  ffmpeg
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "birdnet" "tphakala/birdnet-go" "prebuild" "latest" "/opt/birdnet" "birdnet-go-linux-amd64.tar.gz"

msg_info "Setting up BirdNET-Go"
cp /opt/birdnet/birdnet-go /usr/local/bin/birdnet-go
chmod +x /usr/local/bin/birdnet-go
cp -r /opt/birdnet/libtensorflowlite_c.so /usr/local/lib/ || true
ldconfig
mkdir -p /opt/birdnet/data/clips
msg_ok "Set up BirdNET-Go"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/birdnet.service
[Unit]
Description=BirdNET
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/birdnet/data
ExecStart=/usr/local/bin/birdnet-go realtime
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now birdnet
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
