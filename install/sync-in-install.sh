#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Sync-in/server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

setup_mariadb

MARIADB_DB_NAME="sync_in" MARIADB_DB_USER="sync_in" setup_mariadb_db

msg_info "Installing Sync-in"
mkdir -p /opt/sync-in/data
$STD npm install --prefix /opt/sync-in @sync-in/server
msg_ok "Installed Sync-in"

msg_info "Configuring Sync-in"
ENCRYPT_KEY=$(openssl rand -hex 32)
ACCESS_SECRET=$(openssl rand -hex 32)
REFRESH_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/sync-in/environment.yaml
server:
  port: 8080
mysql:
  url: 'mysql://${MARIADB_DB_USER}:${MARIADB_DB_PASS}@localhost:3306/${MARIADB_DB_NAME}'
auth:
  encryptionKey: '${ENCRYPT_KEY}'
  token:
    access:
      secret: '${ACCESS_SECRET}'
    refresh:
      secret: '${REFRESH_SECRET}'
applications:
  files:
    dataPath: '/opt/sync-in/data'
EOF
msg_ok "Configured Sync-in"

msg_info "Running Database Migrations"
cd /opt/sync-in
$STD npx sync-in-server migrate-db
msg_ok "Ran Database Migrations"

msg_info "Creating Admin User"
cd /opt/sync-in
$STD npx sync-in-server create-user
msg_ok "Created Admin User"

VERSION=$(node -pe "require('/opt/sync-in/node_modules/@sync-in/server/package.json').version" 2>/dev/null || echo "")
[[ -n "$VERSION" ]] && echo "$VERSION" >~/.sync-in

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sync-in.service
[Unit]
Description=Sync-in Server
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sync-in
ExecStart=/opt/sync-in/node_modules/.bin/sync-in-server start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sync-in
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
