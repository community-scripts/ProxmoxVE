#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ErsatzTV/ErsatzTV

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
msg_ok "Installed Dependencies"

msg_info "Installing FFmpeg (Patience)"
wget -q https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
$STD dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
cat <<EOF >/etc/apt/sources.list.d/backports.list
deb https://www.deb-multimedia.org bookworm main non-free
deb https://www.deb-multimedia.org bookworm-backports main
EOF
$STD apt update
DEBIAN_FRONTEND=noninteractive $STD apt-get install -t bookworm-backports ffmpeg -y
rm -rf /etc/apt/sources.list.d/backports.list deb-multimedia-keyring_2016.8.1_all.deb
$STD apt update
msg_ok "Installed FFmpeg"

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

msg_info "Installing ErsatzTV" 
RELEASE=$(curl -s https://api.github.com/repos/ErsatzTV/ErsatzTV/releases | grep -oP '"tag_name": "\K[^"]+' | head -n 1)
wget -qO- "https://github.com/ErsatzTV/ErsatzTV/releases/download/${RELEASE}/ErsatzTV-${RELEASE}-linux-x64.tar.gz" | tar -xz -C /opt
mv "/opt/ErsatzTV-${RELEASE}-linux-x64" /opt/ErsatzTV
msg_ok "Installed ErsatzTV"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ersatzTV.service
[Unit]
Description=ErsatzTV Service
After=multi-user.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ErsatzTV 
ExecStart=/opt/ErsatzTV/ErsatzTV  
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl -q --now enable ersatzTV.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
