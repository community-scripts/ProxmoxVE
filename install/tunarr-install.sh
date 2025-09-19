#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: chrisbenincasa
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tunarr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

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

read -r -p "${TAB3}Do you need the intel-media-va-driver-non-free driver for HW encoding (Debian 12 only)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Intel Hardware Acceleration (non-free)"
  cat <<'EOF' >/etc/apt/sources.list.d/non-free.sources
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: trixie
Components: non-free non-free-firmware

Types: deb deb-src
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: non-free non-free-firmware

Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: trixie-updates
Components: non-free non-free-firmware
EOF
  $STD apt update
  $STD apt -y install {intel-media-va-driver-non-free,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
else
  msg_info "Installing Intel Hardware Acceleration"
  $STD apt -y install {va-driver-all,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
fi
msg_ok "Installed and Set Up Intel Hardware Acceleration"

fetch_and_deploy_gh_release "tunarr" "chrisbenincasa/tunarr" "singlefile" "latest" "/opt/tunarr" "*linux-x64"
fetch_and_deploy_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg" "prebuild" "latest" "/opt/ErsatzTV-ffmpeg" "*-linux64-gpl-7.1.tar.xz"

msg_info "Set ErsatzTV-ffmpeg links"
chmod +x /opt/ErsatzTV-ffmpeg/bin/*
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffmpeg /usr/bin/ffmpeg
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffplay /usr/bin/ffplay
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffprobe /usr/bin/ffprobe
msg_ok "ffmpeg links set"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tunarr.service
[Unit]
Description=Tunarr Service
After=multi-user.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tunarr
ExecStart=/opt/tunarr/tunarr
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tunarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
