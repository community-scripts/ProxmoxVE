#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "rustdesk-hbbr" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*amd64.deb"
fetch_and_deploy_gh_release "rustdesk-hbbs" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*amd64.deb"
fetch_and_deploy_gh_release "rustdesk-utils" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*amd64.deb"
fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*amd64.deb"

msg_info "Configuring RustDesk Server"
ADMINPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
cd /var/lib/rustdesk-api
$STD rustdesk-api reset-admin-pwd $ADMINPASS
{
  echo "RustDesk WebUI"
  echo ""
  echo "Username: admin"
  echo "Password: $ADMINPASS"
} >>~/rustdesk.creds
msg_ok "Configured RustDesk Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
