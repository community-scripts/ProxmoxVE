#!/usr/bin/env bash

#Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://checkmk.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Install Checkmk"
RELEASE=$(curl -fsSL https://api.github.com/repos/checkmk/checkmk/tags | grep "name" | awk '{print substr($2, 3, length($2)-4) }' | tr ' ' '\n' | grep -Ev 'rc|b' | sort -V | tail -n 1)
curl -fsSL "https://download.checkmk.com/checkmk/${RELEASE}/check-mk-raw-${RELEASE}_0.bookworm_amd64.deb" -o "/opt/checkmk.deb"
$STD apt-get install -y /opt/checkmk.deb
rm -rf /opt/checkmk.deb
echo "${RELEASE}" >"/opt/checkmk_version.txt"
msg_ok "Installed Checkmk"

motd_ssh
customize

msg_info "Creating Service"
SITE_NAME="monitoring"
$STD omd create "$SITE_NAME"
MKPASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)

echo -e "$MKPASSWORD\n$MKPASSWORD" | su - "$SITE_NAME" -c "cmk-passwd cmkadmin --stdin"
$STD omd start "$SITE_NAME"

{
  echo "Application-Credentials"
  echo "Username: cmkadmin"
  echo "Password: $MKPASSWORD"
  echo "Site: $SITE_NAME"
} >>~/checkmk.creds

msg_ok "Created Service"

cleanup_lxc
