#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ffmpeg \
  jq \
  imagemagick
msg_ok "Installed Dependencies"

read -r -p "${TAB3}Do you need the intel-media-va-driver-non-free driver for HW encoding (Debian 12 only)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Intel Hardware Acceleration (non-free)"
  cat <<EOF >/etc/apt/sources.list.d/non-free.list

deb http://deb.debian.org/debian bookworm non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm non-free non-free-firmware

deb http://deb.debian.org/debian-security bookworm-security non-free non-free-firmware
deb-src http://deb.debian.org/debian-security bookworm-security non-free non-free-firmware

deb http://deb.debian.org/debian bookworm-updates non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates non-free non-free-firmware
EOF
  $STD apt-get update
  $STD apt-get -y install {intel-media-va-driver-non-free,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
else
  msg_info "Installing Intel Hardware Acceleration"
  $STD apt-get -y install {va-driver-all,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
fi
msg_ok "Installed and Set Up Intel Hardware Acceleration"

msg_info "Installing ASP.NET Core Runtime"
curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
rm -rf packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y aspnetcore-runtime-8.0
msg_ok "Installed ASP.NET Core Runtime"

msg_info "Setup ${APPLICATION}"
$STD ln -svf /usr/bin/ffmpeg /usr/local/bin/ffmpeg
$STD ln -svf /usr/bin/ffprobe /usr/local/bin/ffprobe
temp_file=$(mktemp)
curl -fsSL https://fileflows.com/downloads/zip -o "$temp_file"
$STD unzip -d /opt/fileflows "$temp_file"
(cd /opt/fileflows/Server && dotnet FileFlows.Server.dll --systemd install --root true)
systemctl enable -q --now fileflows
msg_ok "Setup ${APPLICATION}"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
