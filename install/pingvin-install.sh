#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://stonith404.github.io/pingvin-share/introduction

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
  mc \
  git \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install pm2 -g
msg_ok "Installed Node.js"

msg_info "Installing Pingvin Share (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/stonith404/pingvin-share/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
wget -q "https://github.com/stonith404/pingvin-share/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
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
# create and enable pm2-root systemd script
$STD pm2 startup systemd 
# save running pm2 processes so pingvin-share can survive reboots
$STD pm2 save
msg_ok "Installed Pingvin Share"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
