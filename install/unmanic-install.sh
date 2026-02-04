#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.unmanic.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt install -y \
  ffmpeg \
  python3-pip
msg_ok "Installed Dependencies"

setup_hwaccel

msg_info "Installing Unmanic"
$STD pip3 install unmanic
msg_ok "Installed Unmanic"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/unmanic.service
[Unit]
Description=Unmanic - Library Optimiser
After=network-online.target
StartLimitInterval=200
StartLimitBurst=3

[Service]
Type=simple
ExecStart=/usr/local/bin/unmanic
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q unmanic.service
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
