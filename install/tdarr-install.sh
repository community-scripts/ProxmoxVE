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
$STD apt-get install -y handbrake-cli
msg_ok "Installed Dependencies"

msg_info "Setting Up Hardware Acceleration"
$STD apt-get -y install {va-driver-all,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
if [[ "$CTTYPE" == "0" ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser $(id -u -n) video
  $STD adduser $(id -u -n) render
fi
msg_ok "Set Up Hardware Acceleration"

msg_info "Installing Tdarr"
mkdir -p /opt/tdarr
cd /opt/tdarr
RELEASE=$(curl -s https://f000.backblazeb2.com/file/tdarrs/versions.json | grep -oP '(?<="Tdarr_Updater": ")[^"]+' | grep linux_x64 | head -n 1)
wget -q $RELEASE
$STD unzip Tdarr_Updater.zip
rm -rf Tdarr_Updater.zip
chmod +x Tdarr_Updater
./Tdarr_Updater &>/dev/null
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^sgx:x:104:$/render:x:104:root/' -e 's/^render:x:106:root$/sgx:x:106:/' /etc/group
else
  sed -i -e 's/^sgx:x:104:$/render:x:104:/' -e 's/^render:x:106:$/sgx:x:106:/' /etc/group
fi

msg_ok "Installed Tdarr"

msg_info "Creating Service"
service_path="/etc/systemd/system/tdarr-server.service"
echo "[Unit]
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
WantedBy=multi-user.target" >$service_path

service_path="/etc/systemd/system/tdarr-node.service"
echo "[Unit]
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
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q tdarr-server.service
systemctl enable --now -q tdarr-node.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf Tdarr_Updater.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
