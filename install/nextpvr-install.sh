#!/usr/bin/env bash

# Copyright (c) 2021-2025 communtiy-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextpvr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  mediainfo \
  libmediainfo-dev \
  libc6 \
  libgdiplus \
  acl \
  dvb-tools \
  libdvbv5-0 \
  dtv-scan-tables \
  libc6-dev \
  ffmpeg
msg_ok "Installed Dependencies"

msg_info "Setup NextPVR (Patience)"
cd /opt
curl -fsSL "https://nextpvr.com/nextpvr-helper.deb" -o "/opt/nextpvr-helper.deb"
$STD dpkg -i nextpvr-helper.deb
msg_ok "Installed NextPVR"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/nextpvr-helper.deb
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
