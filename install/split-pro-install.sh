#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: johanngrobe
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/oss-apps/split-pro

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" PG_MODULES="cron" setup_postgresql

msg_info "Installing Dependencies"
$STD apt install -y openssl
msg_ok "Installed Dependencies"

PG_DB_NAME="splitpro" PG_DB_USER="splitpro" PG_DB_EXTENSIONS="pg_cron" setup_postgresql_db
fetch_and_deploy_gh_release "split-pro" "oss-apps/split-pro" "tarball"

msg_info "Installing Dependencies"
cd /opt/split-pro
$STD pnpm install --frozen-lockfile
msg_ok "Installed Dependencies"

msg_info "Building Split Pro"
cd /opt/split-pro
mkdir -p /opt/split-pro_data/uploads
ln -sf /opt/split-pro_data/uploads /opt/split-pro/uploads
NEXTAUTH_SECRET=$(openssl rand -base64 32)
cp .env.example .env
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}\"|" .env
sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=\"${NEXTAUTH_SECRET}\"|" .env
sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=\"http://${LOCAL_IP}:3000\"|" .env
sed -i "s|^NEXTAUTH_URL_INTERNAL=.*|NEXTAUTH_URL_INTERNAL=\"http://localhost:3000\"|" .env
sed -i "/^POSTGRES_CONTAINER_NAME=/d" .env
sed -i "/^POSTGRES_USER=/d" .env
sed -i "/^POSTGRES_PASSWORD=/d" .env
sed -i "/^POSTGRES_DB=/d" .env
sed -i "/^POSTGRES_PORT=/d" .env
$STD pnpm build
$STD pnpm exec prisma migrate deploy
msg_ok "Built Split Pro"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/split-pro.service
[Unit]
Description=Split Pro
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/split-pro
EnvironmentFile=/opt/split-pro/.env
ExecStart=/usr/bin/pnpm start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now split-pro
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
