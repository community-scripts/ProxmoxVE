#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bookorbit/bookorbit

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
  ffmpeg \
  poppler-utils
msg_ok "Installed Dependencies"

PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="bookorbit" PG_DB_USER="bookorbit" PG_DB_EXTENSIONS="uuid-ossp,pg_trgm,vector" setup_postgresql_db
NODE_VERSION="24" setup_nodejs
setup_uv

fetch_and_deploy_gh_release "bookorbit" "bookorbit/bookorbit" "tarball"

msg_info "Building Application"
cd /opt/bookorbit
PNPM_VERSION=$(jq -r '.packageManager | ltrimstr("pnpm@")' /opt/bookorbit/package.json)
$STD corepack enable
$STD corepack prepare "pnpm@${PNPM_VERSION}" --activate
$STD pnpm install --frozen-lockfile
$STD pnpm --filter client run build-only
$STD pnpm --filter server run build
cp -r /opt/bookorbit/client/dist /opt/bookorbit/server/public
mkdir -p /opt/bookorbit/server/migrations
cp -r /opt/bookorbit/server/src/db/migrations/. /opt/bookorbit/server/migrations/
chmod +x /opt/bookorbit/server/bin/kepubify/*
msg_ok "Built Application"

msg_info "Setting up Python Runtime"
$STD uv venv /opt/bookorbit-python
$STD uv pip install --python /opt/bookorbit-python/bin/python -r /opt/bookorbit/server/requirements/kobo-cloudscraper.txt
msg_ok "Set up Python Runtime"

msg_info "Configuring Application"
mkdir -p /opt/bookorbit-data/covers /opt/bookorbit-data/book-bucket /opt/bookorbit-books
APP_VER=$(cat ~/.bookorbit)
JWT_SECRET=$(openssl rand -hex 32)
SETUP_BOOTSTRAP_TOKEN=$(openssl rand -hex 16)
cat <<EOF >>~/bookorbit.creds

Setup Token: ${SETUP_BOOTSTRAP_TOKEN}
EOF
cat <<EOF >/opt/bookorbit/.env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
JWT_SECRET=${JWT_SECRET}
SETUP_BOOTSTRAP_TOKEN=${SETUP_BOOTSTRAP_TOKEN}
APP_URL=http://${LOCAL_IP}:3000
CLIENT_URL=http://${LOCAL_IP}:3000
NODE_OPTIONS=--max-old-space-size=2048
APP_DATA_PATH=/opt/bookorbit-data
KOBO_CLOUDSCRAPER_PYTHON=/opt/bookorbit-python/bin/python
BOOK_DOCK_PATH=/opt/bookorbit-data/book-bucket
APP_VERSION=v${APP_VER}
EOF
msg_ok "Configured Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bookorbit.service
[Unit]
Description=BookOrbit Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bookorbit/server
EnvironmentFile=/opt/bookorbit/.env
ExecStartPre=/usr/bin/node /opt/bookorbit/server/dist/scripts/migrate.js
ExecStart=/usr/bin/node /opt/bookorbit/server/dist/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bookorbit
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
