#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hedgedoc/hedgedoc

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  python3
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql
PG_DB_NAME="hedgedoc" PG_DB_USER="hedgedoc" setup_postgresql_db
NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "hedgedoc" "hedgedoc/hedgedoc" "prebuild" "latest" "/opt/hedgedoc" "hedgedoc-*.tar.gz"

msg_info "Installing HedgeDoc Dependencies"
cd /opt/hedgedoc
$STD yarn workspaces focus --production
msg_ok "Installed HedgeDoc Dependencies"

msg_info "Configuring HedgeDoc"
mkdir -p /opt/hedgedoc_data/uploads
cat <<EOF >/opt/hedgedoc_data/config.json
{
  "production": {
    "domain": "${LOCAL_IP}",
    "urlAddPort": true,
    "sessionSecret": "$(openssl rand -hex 64)",
    "db": {
      "dialect": "postgres",
      "host": "localhost",
      "port": 5432,
      "database": "${PG_DB_NAME}",
      "username": "${PG_DB_USER}",
      "password": "${PG_DB_PASS}"
    },
    "uploadsPath": "/opt/hedgedoc_data/uploads",
    "allowAnonymous": false,
    "allowAnonymousEdits": true,
    "enableStatsApi": false
  }
}
EOF
chmod 600 /opt/hedgedoc_data/config.json
msg_ok "Configured HedgeDoc"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hedgedoc.service
[Unit]
Description=HedgeDoc
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hedgedoc
Environment=NODE_ENV=production
Environment=CMD_CONFIG_FILE=/opt/hedgedoc_data/config.json
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hedgedoc
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
