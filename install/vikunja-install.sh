#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  make \
  mc
msg_ok "Installed Dependencies"

msg_info "Setup Vikunja (Patience)"
cd /opt
RELEASE=$(curl -s https://dl.vikunja.io/vikunja/ | grep -oP 'href="/vikunja/\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
wget -q "https://dl.vikunja.io/vikunja/$RELEASE/vikunja-$RELEASE-amd64.deb"
$STD dpkg -i vikunja-$RELEASE-amd64.deb
sed -i 's|^  timezone: .*|  timezone: UTC|' /etc/vikunja/config.yml
sed -i 's|"./vikunja.db"|"/etc/vikunja/vikunja.db"|' /etc/vikunja/config.yml
sed -i 's|./files|/etc/vikunja/files|' /etc/vikunja/config.yml
systemctl start vikunja.service
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Vikunja"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/vikunja-$RELEASE-amd64.deb
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
