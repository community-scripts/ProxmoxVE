#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lobehub/lobehub

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql

CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-bookworm}")
fetch_and_deploy_gh_release "paradedb" "paradedb/paradedb" "binary" "latest" "" "postgresql-17-pg-search_*-1PARADEDB-${CODENAME}_$(dpkg --print-architecture).deb"

msg_info "Configuring pg_search preload library"
if ! grep -q "shared_preload_libraries.*pg_search" /etc/postgresql/17/main/postgresql.conf; then
  echo "shared_preload_libraries = 'pg_search'" >>/etc/postgresql/17/main/postgresql.conf
fi
systemctl restart postgresql
msg_ok "Configured pg_search preload library"

PG_DB_NAME="lobehub" PG_DB_USER="lobehub" PG_DB_EXTENSIONS="vector,pg_search" setup_postgresql_db
NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

fetch_and_deploy_gh_release "lobehub" "lobehub/lobehub" "tarball"

msg_info "Building Application"
cd /opt/lobehub
export DATABASE_URL="postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}"
export DATABASE_DRIVER="node"
export KEY_VAULTS_SECRET="$(openssl rand -base64 32)"
export AUTH_SECRET="$(openssl rand -base64 32)"
export APP_URL="http://localhost:3210"
$STD pnpm install
$STD pnpm run build:docker
msg_ok "Built Application"

msg_info "Configuring Application"
KEY_VAULTS_SECRET=$(openssl rand -base64 32)
AUTH_SECRET=$(openssl rand -base64 32)
cat <<EOF >/opt/lobehub/.env
DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
DATABASE_DRIVER=node
KEY_VAULTS_SECRET=${KEY_VAULTS_SECRET}
AUTH_SECRET=${AUTH_SECRET}
APP_URL=http://${LOCAL_IP}:3210
HOSTNAME=0.0.0.0
PORT=3210
NODE_ENV=production
EOF
msg_ok "Configured Application"

msg_info "Setting Up Standalone"
cp -r /opt/lobehub/.next/static /opt/lobehub/.next/standalone/.next/static
cp -r /opt/lobehub/public /opt/lobehub/.next/standalone/public
cp -r /opt/lobehub/scripts/migrateServerDB/* /opt/lobehub/.next/standalone/
cp -r /opt/lobehub/packages/database/migrations /opt/lobehub/.next/standalone/migrations
msg_ok "Set Up Standalone"

msg_info "Running Database Migrations"
cd /opt/lobehub/.next/standalone
set -a && source /opt/lobehub/.env && set +a
$STD node /opt/lobehub/.next/standalone/docker.cjs
msg_ok "Ran Database Migrations"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lobehub.service
[Unit]
Description=LobeHub
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lobehub/.next/standalone
EnvironmentFile=/opt/lobehub/.env
ExecStart=/usr/bin/node /opt/lobehub/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now lobehub
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
