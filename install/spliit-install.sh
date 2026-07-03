#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: phof
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/spliit-app/spliit

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="16" setup_postgresql
PG_DB_NAME="spliit" PG_DB_USER="spliit" setup_postgresql_db
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "spliit" "spliit-app/spliit" "tarball"

msg_info "Configuring Application"
cat <<EOF >/opt/spliit/.env
POSTGRES_PRISMA_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?schema=public
POSTGRES_URL_NON_POOLING=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?schema=public
NEXT_PUBLIC_DEFAULT_CURRENCY_CODE=
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
PORT=3000
HOSTNAME=0.0.0.0
EOF
msg_ok "Configured Application"

msg_info "Building Application"
cd /opt/spliit
$STD npm ci --ignore-scripts
$STD npx prisma generate
$STD npm run build
msg_ok "Built Application"

msg_info "Running Database Migrations"
cd /opt/spliit
$STD npx prisma migrate deploy
msg_ok "Ran Database Migrations"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/spliit.service
[Unit]
Description=Spliit
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/spliit
EnvironmentFile=/opt/spliit/.env
ExecStart=/usr/bin/npm run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spliit
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
