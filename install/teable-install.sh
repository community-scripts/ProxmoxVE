#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teableio/teable

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
  python3 \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="teable" PG_DB_USER="teable" setup_postgresql_db

fetch_and_deploy_gh_release "teable" "teableio/teable" "tarball"

msg_info "Setting up Teable"
cd /opt/teable
TEABLE_VERSION=$(cat ~/.teable)
echo "NEXT_PUBLIC_BUILD_VERSION=\"${TEABLE_VERSION}\"" >>apps/nextjs-app/.env
export HUSKY=0
export NODE_OPTIONS="--max-old-space-size=8192"
$STD pnpm install --frozen-lockfile
$STD pnpm -F @teable/db-main-prisma prisma-generate --schema ./prisma/postgres/schema.prisma
msg_ok "Set up Teable"

msg_info "Building Teable"
NODE_ENV=production NEXT_BUILD_ENV_TYPECHECK=false \
  $STD pnpm -r --filter '!playground' run build
msg_ok "Built Teable"

msg_info "Running Database Migrations"
PRISMA_DATABASE_URL="postgresql://teable:${PG_DB_PASS}@localhost:5432/teable?schema=public" \
  $STD pnpm -F @teable/db-main-prisma prisma-migrate deploy --schema ./prisma/postgres/schema.prisma
msg_ok "Ran Database Migrations"

msg_info "Configuring Teable"
mkdir -p /opt/teable/.assets /opt/teable/.temporary
SECRET_KEY=$(openssl rand -base64 32)
cat <<EOF >/opt/teable/.env
PRISMA_DATABASE_URL=postgresql://teable:${PG_DB_PASS}@localhost:5432/teable?schema=public&statement_cache_size=1
PUBLIC_ORIGIN=http://${LOCAL_IP}:3000
SECRET_KEY=${SECRET_KEY}
PORT=3000
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
BACKEND_CACHE_PROVIDER=sqlite
BACKEND_CACHE_SQLITE_URI=sqlite:///opt/teable/.assets/.cache.db
NEXTJS_DIR=apps/nextjs-app
EOF
ln -sf /opt/teable /app
rm -rf /opt/teable/static
if [ -d "/opt/teable/apps/nestjs-backend/static/static" ]; then
  ln -sf /opt/teable/apps/nestjs-backend/static/static /opt/teable/static
else
  ln -sf /opt/teable/apps/nestjs-backend/static /opt/teable/static
fi
msg_ok "Configured Teable"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/teable.service
[Unit]
Description=Teable
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/teable
EnvironmentFile=/opt/teable/.env
ExecStart=/usr/bin/node apps/nestjs-backend/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now teable
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
