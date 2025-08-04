#!/usr/bin/env bash

# Copyright (c) 2025 Community Scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sqlite3 \
  yq
msg_ok "Installed Dependencies"

NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_release "tududi" "chrisvel/tududi"

msg_info "Configuring Tududi"
cd /opt/tududi
$STD npm install
export NODE_ENV=production
$STD npm run frontend:build
mv ./dist ./backend
mv ./public/locales ./backend/dist
mv ./public/favicon.* ./backend/dist
msg_ok "Configured Tududi"

msg_info "Creating env and database"
DB_LOCATION="/opt/tududi-db"
UPLOAD_DIR="/opt/tududi-uploads"
mkdir -p {"$DB_LOCATION","$UPLOAD_DIR"}
SECRET="$(openssl rand -hex 64)"
sed -e 's/^GOOGLE/# &/' \
  -e '/TUDUDI_SESSION/s/^# //' \
  -e '/NODE_ENV/s/^# //' \
  -e "s/your_session_secret_here/$SECRET/" \
  -e 's/development/production/' \
  -e "\$a\DB_FILE=$DB_LOCATION/production.sqlite3" \
  -e "\$a\TUDUDI_UPLOAD_PATH=$UPLOAD_DIR" \
  /opt/tududi/backend/.env.example >/opt/tududi/backend/.env
export DB_FILE="$DB_LOCATION/production.sqlite3"
$STD npm run db:init
msg_ok "Created env and database"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/tududi.service
[Unit]
Description=Tududi Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/tududi
EnvironmentFile=/opt/tududi/backend/.env
ExecStart=/usr/bin/npm run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tududi
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
