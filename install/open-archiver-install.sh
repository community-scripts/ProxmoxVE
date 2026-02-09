#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openarchiver.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependendencies"
$STD apt install -y valkey
msg_ok "Installed dependendencies"

NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="openarchiver_db" PG_DB_USER="openarchiver" setup_postgresql_db

setup_meilisearch
fetch_and_deploy_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver" "tarball"
JWT_KEY="$(openssl rand -hex 32)"
SECRET_KEY="$(openssl rand -hex 32)"

msg_info "Setting up Open Archiver"
mkdir -p /opt/openarchiver-data
cd /opt/openarchiver
cp .env.example .env
sed -i "s|^NODE_ENV=.*|NODE_ENV=production|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_DB=.*|POSTGRES_DB=$PG_DB_NAME|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_USER=.*|POSTGRES_USER=$PG_DB_USER|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$PG_DB_PASS|g" /opt/openarchiver/.env
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME\"|g" /opt/openarchiver/.env
sed -i "s|^MEILI_HOST=.*|MEILI_HOST=http://localhost:7700|g" /opt/openarchiver/.env
sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$MEILISEARCH_MASTER_KEY|g" /opt/openarchiver/.env
sed -i "s|^REDIS_HOST=.*|REDIS_HOST=localhost|g" /opt/openarchiver/.env
sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=|g" /opt/openarchiver/.env
sed -i "s|^STORAGE_LOCAL_ROOT_PATH=.*|STORAGE_LOCAL_ROOT_PATH=/opt/openarchiver-data|g" /opt/openarchiver/.env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_KEY|g" /opt/openarchiver/.env
sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$SECRET_KEY|g" /opt/openarchiver/.env
sed -i "s|^TIKA_URL=.*|TIKA_URL=|g" /opt/openarchiver/.env
sed -i "s|^ORIGIN=.*|ORIGIN=http://$LOCAL_IP:3000|g" /opt/openarchiver/.env
$STD pnpm install --shamefully-hoist --frozen-lockfile --prod=false
$STD pnpm run build:oss
$STD pnpm db:migrate
msg_ok "Setup Open Archiver"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openarchiver.service
[Unit]
Description=Open Archiver Service
After=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/opt/openarchiver/.env
WorkingDirectory=/opt/openarchiver
ExecStart=/usr/bin/pnpm docker-start:oss
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openarchiver
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
