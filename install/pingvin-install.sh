#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://stonith404.github.io/pingvin-share/introduction

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pm2" setup_nodejs

msg_info "Installing Pingvin Share (Patience)"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/stonith404/pingvin-share/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/stonith404/pingvin-share/archive/refs/tags/v${RELEASE}.zip" -o "v${RELEASE}.zip"
$STD unzip v${RELEASE}.zip
echo "${RELEASE}" >"/opt/pingvin_version.txt"
mv pingvin-share-${RELEASE} /opt/pingvin-share
cd /opt/pingvin-share/backend
$STD npm install
$STD npm run build
$STD pm2 start --name="pingvin-share-backend" npm -- run prod
cd ../frontend
sed -i '/"admin.config.smtp.allow-unauthorized-certificates":\|admin.config.smtp.allow-unauthorized-certificates.description":/,+1d' ./src/i18n/translations/fr-FR.ts
$STD npm install
$STD npm run build
$STD pm2 start --name="pingvin-share-frontend" npm -- run start
$STD pm2 startup systemd
$STD pm2 save
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Pingvin Share"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
