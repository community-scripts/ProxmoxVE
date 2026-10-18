#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/adminsyspro/proxcenter-ui

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="26" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="proxcenter" PG_DB_USER="proxcenter" setup_postgresql_db

fetch_and_deploy_gh_release "proxcenter" "adminsyspro/proxcenter-ui" "tarball"

msg_info "Building ProxCenter"
cd /opt/proxcenter/frontend
$STD npm ci --legacy-peer-deps --ignore-scripts
$STD npm run build:icons
$STD npx prisma generate
NODE_OPTIONS="--max-old-space-size=4608" $STD npm run build
msg_ok "Built ProxCenter"

msg_info "Configuring ProxCenter"
mkdir -p /opt/proxcenter_data
cat <<EOF >/opt/proxcenter_data/.env
NODE_ENV=production
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?schema=public
APP_SECRET=$(openssl rand -base64 32)
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=http://${LOCAL_IP}:3000
APP_URL=http://${LOCAL_IP}:3000
PROXCENTER_INSTANCE_ID=proxcenter
EOF
chmod 600 /opt/proxcenter_data/.env
msg_ok "Configured ProxCenter"

msg_info "Migrating Database"
set -a && source /opt/proxcenter_data/.env && set +a
$STD npx prisma migrate deploy
$STD npx prisma db seed
msg_ok "Migrated Database"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/proxcenter.service
[Unit]
Description=ProxCenter
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/proxcenter/frontend
EnvironmentFile=/opt/proxcenter_data/.env
ExecStart=/usr/bin/node start.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now proxcenter
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
