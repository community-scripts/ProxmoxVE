#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com/ | Github: https://github.com/chrisvel/tududi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="tududi" PG_DB_USER="tududi" setup_postgresql_db
fetch_and_deploy_gh_release "tududi" "chrisvel/tududi" "tarball" "latest" "/opt/tududi"

msg_info "Configuring Tududi"
cd /opt/tududi
$STD npm install
export NODE_ENV=production
$STD npm run frontend:build
mv ./dist ./backend
msg_ok "Configured Tududi"

msg_info "Creating env"
mkdir -p /opt/tududi-uploads
SECRET="$(openssl rand -hex 64)"
sed -e '/^NODE_ENV=/s/=.*$/=production/' \
  -e 's/^TUDUDI_USER/# TUDUDI_USER/g' \
  -e "s/^TUDUDI_SESSION_SECRET=.*/TUDUDI_SESSION_SECRET=${SECRET}/" \
  -e "s|^DATABASE_URL=.*|DATABASE_URL=postgres://tududi:${PG_DB_PASS}@localhost:5432/tududi|" \
  /opt/tududi/backend/.env.example >/opt/tududi/backend/.env
echo "TUDUDI_UPLOAD_PATH=/opt/tududi-uploads" >>/opt/tududi/backend/.env
msg_ok "Created env"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/tududi.service
[Unit]
Description=Tududi Service
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/tududi/backend
EnvironmentFile=/opt/tududi/backend/.env
ExecStart=/usr/bin/bash /opt/tududi/backend/cmd/start.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tududi
msg_ok "Created service"

motd_ssh
customize
cleanup_lxc
