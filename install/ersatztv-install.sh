#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ersatztv.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing FFmpeg (Patience)"
cd /usr/local/bin
curl -fsSL "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" -o "ffmpeg-release-amd64-static.tar.xz"
$STD tar -xvf ffmpeg-release-amd64-static.tar.xz
rm -f ffmpeg-*.tar.xz
cd ffmpeg-*
mv ffmpeg ffprobe /usr/local/bin/
rm -rf /usr/local/bin/ffmpeg-*
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
temp_file=$(mktemp)
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/ErsatzTV/ErsatzTV/releases | grep -oP '"tag_name": "\K[^"]+' | head -n 1)
curl -fsSL "https://github.com/ErsatzTV/ErsatzTV/releases/download/${RELEASE}/ErsatzTV-${RELEASE}-linux-x64.tar.gz" -o "$temp_file"
tar -xzf "$temp_file"
mv /opt/ErsatzTV-${RELEASE}-linux-x64 /opt/ErsatzTV
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
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
systemctl enable -q --now ersatzTV
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f ${temp_file}
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
