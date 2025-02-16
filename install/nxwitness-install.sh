#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nxvms.com/download/releases/linux

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  make \
  net-tools \
  ffmpeg \
  cifs-utils \
  libtalloc2 \
  libwbclient0 \
  keyutils
msg_ok "Installed Dependencies"

msg_info "Setup Nx Witness"
cd /tmp
BASE_URL="https://updates.networkoptix.com/default/index.html"
RELEASE=$(curl -s "$BASE_URL" | grep -oP '(?<=<b>)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=</b>)' | head -n 1)
DETAIL_PAGE=$(curl -s "$BASE_URL#note_$RELEASE")
DOWNLOAD_URL=$(echo "$DETAIL_PAGE" | grep -oP "https://updates.networkoptix.com/default/$RELEASE/linux/nxwitness-server-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-linux_x64\.deb" | head -n 1)
wget -q "$DOWNLOAD_URL" -O "nxwitness-server-$RELEASE-linux_x64.deb"
export DEBIAN_FRONTEND=noninteractive
$STD dpkg -i nxwitness-server-$RELEASE-linux_x64.deb
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup Nx Witness"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /tmp/nxwitness-server-$RELEASE-linux_x64.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"