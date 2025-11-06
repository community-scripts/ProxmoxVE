#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary"
fetch_and_deploy_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver" "tarball"
JWT_KEY="$(openssl rand -hex 32)"
SECRET_KEY="$(openssl rand -hex 32)"
IP_ADDR=$(hostname -I | awk '{print $1}')

msg_info "Setting up PostgreSQL"
DB_NAME="openarchiver_db"
DB_USER="openarchiver"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-18)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "Open Archiver DB Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
} >>~/openarchiver.creds
msg_ok "Set up PostgreSQL"

msg_info "Configuring MeiliSearch"
curl -fsSL https://raw.githubusercontent.com/meilisearch/meilisearch/latest/config.toml -o /etc/meilisearch.toml
MASTER_KEY=$(openssl rand -base64 12)
sed -i \
  -e 's|^env =.*|env = "production"|' \
  -e "s|^# master_key =.*|master_key = \"$MASTER_KEY\"|" \
  -e 's|^db_path =.*|db_path = "/var/lib/meilisearch/data"|' \
  -e 's|^dump_dir =.*|dump_dir = "/var/lib/meilisearch/dumps"|' \
  -e 's|^snapshot_dir =.*|snapshot_dir = "/var/lib/meilisearch/snapshots"|' \
  -e 's|^# no_analytics = true|no_analytics = true|' \
  -e 's|^http_addr =.*|http_addr = "127.0.0.1:7700"|' \
  /etc/meilisearch.toml

cat <<EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=Meilisearch
After=network.target

[Service]
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now meilisearch
sleep 5
msg_ok "Configured MeiliSearch"

msg_info "Setting up Open Archiver"
mkdir -p /opt/openarchiver-data
cd /opt/openarchiver
cp .env.example .env
sed -i "s|^NODE_ENV=.*|NODE_ENV=production|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_DB=.*|POSTGRES_DB=openarchiver_db|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_USER=.*|POSTGRES_USER=openarchiver|g" /opt/openarchiver/.env
sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASS|g" /opt/openarchiver/.env
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"postgresql://openarchiver:$DB_PASS@localhost:5432/openarchiver_db\"|g" /opt/openarchiver/.env
sed -i "s|^MEILI_HOST=.*|MEILI_HOST=http://localhost:7700|g" /opt/openarchiver/.env
sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$MASTER_KEY|g" /opt/openarchiver/.env
sed -i "s|^REDIS_HOST=.*|REDIS_HOST=localhost|g" /opt/openarchiver/.env
sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=|g" /opt/openarchiver/.env
sed -i "s|^STORAGE_LOCAL_ROOT_PATH=.*|STORAGE_LOCAL_ROOT_PATH=/opt/openarchiver-data|g" /opt/openarchiver/.env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_KEY|g" /opt/openarchiver/.env
sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$SECRET_KEY|g" /opt/openarchiver/.env
sed -i "s|^TIKA_URL=.*|TIKA_URL=|g" /opt/openarchiver/.env
echo "ORIGIN=http://$IP_ADDR:3000" >> /opt/openarchiver/.env
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

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
