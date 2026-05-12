#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZhFahim/anchor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="anchor" PG_DB_USER="anchor" setup_postgresql_db

fetch_and_deploy_gh_release "anchor" "ZhFahim/anchor" "tarball"

msg_info "Building Server"
cd /opt/anchor/server
$STD pnpm install --frozen-lockfile
$STD pnpm prisma generate
$STD pnpm build
[[ -d src/generated ]] && mkdir -p dist/src && cp -R src/generated dist/src/
msg_ok "Built Server"

msg_info "Building Web Interface"
cd /opt/anchor/web
$STD pnpm install --frozen-lockfile
SERVER_URL=http://127.0.0.1:3001 $STD pnpm build
cp -r .next/static .next/standalone/.next/static
cp -r public .next/standalone/public
msg_ok "Built Web Interface"

msg_info "Configuring Application"
JWT_SECRET=$(openssl rand -base64 32)
cat <<EOF >/opt/anchor/.env
APP_URL=http://${LOCAL_IP}:3000
JWT_SECRET=${JWT_SECRET}
DATABASE_URL=postgresql://anchor:${PG_DB_PASS}@localhost:5432/anchor
PG_HOST=localhost
PG_USER=anchor
PG_PASSWORD=${PG_DB_PASS}
PG_DATABASE=anchor
PG_PORT=5432
EOF
msg_ok "Configured Application"

msg_info "Running Database Migrations"
cd /opt/anchor/server
set -a && source /opt/anchor/.env && set +a
$STD pnpm prisma migrate deploy
msg_ok "Ran Database Migrations"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/anchor-server.service
[Unit]
Description=Anchor API Server
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anchor/server
EnvironmentFile=/opt/anchor/.env
ExecStart=/usr/bin/node dist/src/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/anchor-web.service
[Unit]
Description=Anchor Web Interface
After=network.target anchor-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anchor/web/.next/standalone
EnvironmentFile=/opt/anchor/.env
Environment=PORT=3000 HOSTNAME=0.0.0.0 NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now anchor-server anchor-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
