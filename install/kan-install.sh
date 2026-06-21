#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kanbn/kan

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
  git
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="kan" PG_DB_USER="kan" setup_postgresql_db
NODE_VERSION="20" NODE_MODULE="corepack,pnpm" setup_nodejs

fetch_and_deploy_gh_tag "kan" "kanbn/kan" "latest"

msg_info "Configuring Application"
AUTH_SECRET=$(openssl rand -base64 32)
cat <<EOF >/opt/kan/.env
NEXT_PUBLIC_BASE_URL=http://${LOCAL_IP}:3000
BETTER_AUTH_SECRET=${AUTH_SECRET}
BETTER_AUTH_TRUSTED_ORIGINS=http://${LOCAL_IP}:3000
POSTGRES_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
NEXT_PUBLIC_ALLOW_CREDENTIALS=true
TRELLO_APP_API_KEY=
TRELLO_APP_API_SECRET=
HOSTNAME=0.0.0.0
PORT=3000
NODE_ENV=production
EOF
msg_ok "Configured Application"

msg_info "Building Application"
cd /opt/kan
set -a && source /opt/kan/.env && set +a
export NEXT_PUBLIC_USE_STANDALONE_OUTPUT=true NEXT_PUBLIC_BASE_URL BETTER_AUTH_TRUSTED_ORIGINS NEXT_PUBLIC_ALLOW_CREDENTIALS BETTER_AUTH_SECRET
$STD pnpm install --ignore-scripts --prod=false
export CI=true
find /opt/kan/packages /opt/kan/apps -name 'tsconfig.json' -exec sed -i 's|"@kan/tsconfig/|"../../tooling/typescript/|g' {} +
$STD pnpm build --filter=@kan/web
unset NEXT_PUBLIC_USE_STANDALONE_OUTPUT CI
msg_ok "Built Application"

msg_info "Setting up Standalone"
mkdir -p /opt/kan/apps/web/.next/standalone/apps/web/.next/static
cp -r /opt/kan/apps/web/.next/static/* /opt/kan/apps/web/.next/standalone/apps/web/.next/static/
cp -r /opt/kan/apps/web/public /opt/kan/apps/web/.next/standalone/apps/web/public
msg_ok "Set up Standalone"

msg_info "Running Database Migrations"
cd /opt/kan/packages/db
POSTGRES_URL="postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}" $STD pnpm exec drizzle-kit migrate
msg_ok "Ran Database Migrations"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kan.service
[Unit]
Description=Kan Board
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kan/apps/web/.next/standalone
EnvironmentFile=/opt/kan/.env
ExecStart=/usr/bin/node apps/web/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kan
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
