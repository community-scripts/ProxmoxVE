#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/twentyhq/twenty

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
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="twenty_db" PG_DB_USER="twenty" PG_DB_SCHEMA_PERMS="true" PG_DB_EXTENSIONS="vector" setup_postgresql_db
NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "twenty" "twentyhq/twenty" "tarball"

msg_info "Building Application"
cd /opt/twenty
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
$STD corepack prepare yarn@4.9.2 --activate
yarn install --immutable >/dev/null 2>&1 || $STD yarn install
export NODE_OPTIONS="--max-old-space-size=4096"
$STD npx nx run twenty-server:build
$STD npx nx build twenty-front
cp -r /opt/twenty/packages/twenty-front/build /opt/twenty/packages/twenty-server/dist/front
unset NODE_OPTIONS
msg_ok "Built Application"

msg_info "Configuring Application"
APP_SECRET=$(openssl rand -base64 32)
mkdir -p /opt/twenty/packages/twenty-server/.local-storage
cat <<EOF >/opt/twenty/.env
NODE_PORT=3000
PG_DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
REDIS_URL=redis://localhost:6379
SERVER_URL=http://${LOCAL_IP}:3000
APP_SECRET=${APP_SECRET}
STORAGE_TYPE=local
NODE_ENV=production
EOF
msg_ok "Configured Application"

msg_info "Running Database Migrations"
cd /opt/twenty/packages/twenty-server
set -a && source /opt/twenty/.env && set +a
$STD yarn database:init:prod
msg_ok "Ran Database Migrations"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/twenty-server.service
[Unit]
Description=Twenty CRM Server
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/twenty/packages/twenty-server
EnvironmentFile=/opt/twenty/.env
ExecStart=/usr/bin/node dist/main
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/twenty-worker.service
[Unit]
Description=Twenty CRM Worker
After=network.target postgresql.service redis-server.service twenty-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/twenty/packages/twenty-server
EnvironmentFile=/opt/twenty/.env
Environment=DISABLE_DB_MIGRATIONS=true
Environment=DISABLE_CRON_JOBS_REGISTRATION=true
ExecStart=/usr/bin/node dist/queue-worker/queue-worker
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now redis-server twenty-server twenty-worker
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
