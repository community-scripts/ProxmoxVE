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

hbbr_filename=$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest" |
  jq -r '.assets[].name' |
  grep -E '^rustdesk-server-hbbr_[0-9]+\.[0-9]+\.[0-9]+_amd64\.deb$')
hbbs_filename=$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest" |
  jq -r '.assets[].name' |
  grep -E '^rustdesk-server-hbbs_[0-9]+\.[0-9]+\.[0-9]+_amd64\.deb$')
utils_filename=$(curl -fsSL "https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest" |
  jq -r '.assets[].name' |
  grep -E '^rustdesk-server-utils_[0-9]+\.[0-9]+\.[0-9]+_amd64\.deb$')

fetch_and_deploy_gh_release "rustdesk-hbbr" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "$hbbr_filename"
fetch_and_deploy_gh_release "rustdesk-hbbs" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "$hbbs_filename"
fetch_and_deploy_gh_release "rustdesk-utils" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "$utils_filename"
fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server_*_amd64.deb"

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
