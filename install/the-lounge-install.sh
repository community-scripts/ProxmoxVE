#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://thelounge.chat/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest,node-gyp" setup_nodejs

msg_info "Installing The Lounge"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/thelounge/thelounge-deb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb" -o "./thelounge_${RELEASE}_all.deb"
$STD dpkg -i ./thelounge_${RELEASE}_all.deb
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed The Lounge"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/thelounge_${RELEASE}_all.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
