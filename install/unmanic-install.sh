#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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

msg_info "Setting Up Hardware Acceleration"
$STD apt -y install \
  va-driver-all \
  ocl-icd-libopencl1 \
  vainfo \
  intel-gpu-tools \
  mesa-va-drivers \
  mesa-vdpau-drivers \
  intel-media-va-driver
if [[ "$CTTYPE" == "0" ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser $(id -u -n) video
  $STD adduser $(id -u -n) render
  VIDEO_GID=$(getent group video | cut -d: -f3)
  RENDER_GID=$(getent group render | cut -d: -f3)
  if [[ -n "$VIDEO_GID" && -n "$RENDER_GID" ]]; then
    sed -i "s/^video:x:[0-9]*:/video:x:$VIDEO_GID:/" /etc/group
    sed -i "s/^render:x:[0-9]*:/render:x:$RENDER_GID:/" /etc/group
  fi
else
  VIDEO_GID=$(getent group video | cut -d: -f3)
  RENDER_GID=$(getent group render | cut -d: -f3)
fi
msg_ok "Set Up Hardware Acceleration"

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

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
