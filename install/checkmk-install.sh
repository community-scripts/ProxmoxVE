#!/usr/bin/env bash

#Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE


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
  mc 
msg_ok "Installed Dependencies"

msg_info "Install Checkmk"
RELEASE=$(curl -fsSL https://api.github.com/repos/checkmk/checkmk/tags | grep "name" | awk '{print substr($2, 3, length($2)-4) }' | grep -v "*-rc" | tail -n +2 | head -n 1)
wget -q https://download.checkmk.com/checkmk/${RELEASE}/check-mk-raw-${RELEASE}_0.bookworm_amd64.deb -O /opt/checkmk.deb
$STD apt-get install -y /opt/checkmk.deb
echo "${RELEASE}" >"/opt/checkmk_version.txt"
msg_ok "Installed Checkmk"

motd_ssh
customize

msg_info "Creating Service"
PASSWORD=$(omd create monitoring | grep "password:" | awk '{print $NF}')
$STD omd start
{
    echo "Application-Credentials"
    echo "Username: cmkadmin"
    echo "Password: $PASSWORD"
} >> ~/checkmk.creds
msg_ok "Created Service"

msg_info "Cleaning up"
rm -rf /opt/checkmk.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
