#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ridafkih/keeper.sh

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  redis-server \
  unzip
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="keeper" PG_DB_USER="keeper" setup_postgresql_db

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "keeper" "ridafkih/keeper.sh" "tarball"

msg_info "Building Keeper"
cd /opt/keeper
$STD bun install --frozen-lockfile
$STD bun run --cwd services/api build
$STD bun run --cwd services/cron build
$STD bun run --cwd services/worker build
$STD bun run --cwd applications/web build
msg_ok "Built Keeper"

msg_info "Configuring Keeper"
mkdir -p /opt/keeper_data
cat <<EOF >/opt/keeper_data/.env
ENV=production
DATABASE_URL=postgresql://keeper:${PG_DB_PASS}@127.0.0.1:5432/keeper
REDIS_URL=redis://127.0.0.1:6379
BETTER_AUTH_URL=http://${LOCAL_IP}:3000
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)
TRUSTED_ORIGINS=http://${LOCAL_IP}:3000
API_PORT=3001
PORT=3000
VITE_API_URL=http://127.0.0.1:3001
COMMERCIAL_MODE=false
WORKER_JOB_QUEUE_ENABLED=true
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
MICROSOFT_CLIENT_ID=
MICROSOFT_CLIENT_SECRET=
EOF
chmod 600 /opt/keeper_data/.env
msg_ok "Configured Keeper"

msg_info "Migrating Keeper Database"
$STD bun --env-file=/opt/keeper_data/.env packages/database/scripts/migrate.ts
msg_ok "Migrated Keeper Database"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/keeper-api.service
[Unit]
Description=Keeper API
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/keeper
EnvironmentFile=/opt/keeper_data/.env
ExecStart=/usr/local/bin/bun /opt/keeper/services/api/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/keeper-cron.service
[Unit]
Description=Keeper Cron
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/keeper
EnvironmentFile=/opt/keeper_data/.env
ExecStart=/usr/local/bin/bun /opt/keeper/services/cron/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/keeper-worker.service
[Unit]
Description=Keeper Worker
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/keeper
EnvironmentFile=/opt/keeper_data/.env
ExecStart=/usr/local/bin/bun /opt/keeper/services/worker/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/keeper-web.service
[Unit]
Description=Keeper Web
After=network.target keeper-api.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/keeper/applications/web
EnvironmentFile=/opt/keeper_data/.env
ExecStart=/usr/local/bin/bun /opt/keeper/applications/web/dist/server-entry/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now keeper-api keeper-cron keeper-worker keeper-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
