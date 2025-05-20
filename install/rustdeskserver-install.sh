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

msg_info "Setup RustDesk"

RELEASE=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
APIRELEASE=$(curl -fsSL https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
TEMPDIR=$(mktemp -d)

curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbr_${RELEASE}_amd64.deb" \
  -o "${TEMPDIR}/rustdesk-server-hbbr_${RELEASE}_amd64.deb"
curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbs_${RELEASE}_amd64.deb" \
  -o "${TEMPDIR}/rustdesk-server-hbbs_${RELEASE}_amd64.deb"
curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-utils_${RELEASE}_amd64.deb" \
  -o "${TEMPDIR}/rustdesk-server-utils_${RELEASE}_amd64.deb"
curl -fsSL "https://github.com/lejianwen/rustdesk-api/releases/download/v${APIRELEASE}/rustdesk-api-server_${APIRELEASE}_amd64.deb" \
  -o "${TEMPDIR}/rustdesk-api-server_${APIRELEASE}_amd64.deb"
$STD dpkg -i "${TEMPDIR}"/*.deb
ADMINPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
cd /var/lib/rustdesk-api
$STD rustdesk-api reset-admin-pwd $ADMINPASS
{
  echo "RustDesk WebUI"
  echo ""
  echo "Username: admin"
  echo "Password: $ADMINPASS"
} >>~/rustdesk.creds
echo "${RELEASE}" >/opt/rustdesk_version.txt
msg_ok "Setup RustDesk"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $TEMPDIR
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
