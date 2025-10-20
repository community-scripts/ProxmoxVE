#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jellyfin.org/

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

msg_info "Installing Jellyfin"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
if ! dpkg -s libjemalloc2 >/dev/null 2>&1; then
  $STD apt install -y libjemalloc2
fi
if [[ ! -f /usr/lib/libjemalloc.so ]]; then
  ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so
fi
if [[ ! -d /etc/apt/keyrings ]]; then
  mkdir -p /etc/apt/keyrings
fi
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
cat <<EOF >/etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${PCT_OSTYPE}
Suites: ${VERSION}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF

$STD apt update
$STD apt install -y jellyfin
sed -i 's/"MinimumLevel": "Information"/"MinimumLevel": "Error"/g' /etc/jellyfin/logging.json

chown -R jellyfin:adm /etc/jellyfin
sleep 10
systemctl restart jellyfin
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:root,jellyfin/' -e 's/^render:x:108:root,jellyfin$/ssl-cert:x:108:/' /etc/group
else
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:jellyfin/' -e 's/^render:x:108:jellyfin$/ssl-cert:x:108:/' /etc/group
fi
msg_ok "Installed Jellyfin"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
