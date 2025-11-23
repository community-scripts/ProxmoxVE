#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://home.tdarr.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y handbrake-cli
msg_ok "Installed Dependencies"

msg_info "Installing Tdarr"
mkdir -p /opt/tdarr
cd /opt/tdarr
RELEASE=$(curl -fsSL https://f000.backblazeb2.com/file/tdarrs/versions.json | grep -oP '(?<="Tdarr_Updater": ")[^"]+' | grep linux_x64 | head -n 1)
curl -fsSL "$RELEASE" -o Tdarr_Updater.zip
$STD unzip Tdarr_Updater.zip
chmod +x Tdarr_Updater
$STD ./Tdarr_Updater
rm -rf /opt/tdarr/Tdarr_Updater.zip
msg_ok "Installed Tdarr"

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

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tdarr-server.service
[Unit]
Description=Tdarr Server Daemon
After=network.target
# Enable if using ZFS, edit and enable if other FS mounting is required to access directory
#Requires=zfs-mount.service

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/tdarr/Tdarr_Server
ExecStartPre=/opt/tdarr/Tdarr_Updater
ExecStart=/opt/tdarr/Tdarr_Server/Tdarr_Server
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/tdarr-node.service
[Unit]
Description=Tdarr Node Daemon
After=network.target
Requires=tdarr-server.service

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/tdarr/Tdarr_Node
ExecStart=/opt/tdarr/Tdarr_Node/Tdarr_Node
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q tdarr-server tdarr-node
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
