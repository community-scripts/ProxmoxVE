#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: lucasfell
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghostfol.io/

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
  openssl \
  ca-certificates \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
NODE_VERSION="24" setup_nodejs
PG_DB_NAME="ghostfolio" PG_DB_USER="ghostfolio" PG_DB_SCHEMA_PERMS="true" setup_postgresql_db

fetch_and_deploy_gh_release "ghostfolio" "ghostfolio/ghostfolio" "tarball" "latest" "/opt/ghostfolio"

msg_info "Setup Ghostfolio"
REDIS_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
ACCESS_TOKEN_SALT=$(openssl rand -base64 32)
JWT_SECRET_KEY=$(openssl rand -base64 32)
sed -i "s/# requirepass foobared/requirepass $REDIS_PASS/" /etc/redis/redis.conf
systemctl restart redis-server
cd /opt/ghostfolio
$STD npm ci
$STD npm run build:production
{
  echo "Redis Password: $REDIS_PASS"
  echo "Access Token Salt: $ACCESS_TOKEN_SALT"
  echo "JWT Secret Key: $JWT_SECRET_KEY"
} >>~/ghostfolio.creds
msg_ok "Built Ghostfolio"

echo -e ""
msg_custom "🪙" "$YW" "CoinGecko API keys are optional but provide better cryptocurrency data."
msg_custom "🪙" "$YW" "You can skip this and add them later by editing /opt/ghostfolio/.env"
echo -e ""
read -rp "${TAB3}CoinGecko Demo API key (press Enter to skip): " COINGECKO_DEMO_KEY
read -rp "${TAB3}CoinGecko Pro API key (press Enter to skip): " COINGECKO_PRO_KEY

msg_info "Setting up Environment"
cat <<EOF >/opt/ghostfolio/.env
DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME?connect_timeout=300&sslmode=prefer
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASS
ACCESS_TOKEN_SALT=$ACCESS_TOKEN_SALT
JWT_SECRET_KEY=$JWT_SECRET_KEY
NODE_ENV=production
PORT=3333
HOST=0.0.0.0
TZ=Etc/UTC
EOF

if [[ -n "${COINGECKO_DEMO_KEY:-}" ]]; then
  echo "API_KEY_COINGECKO_DEMO=$COINGECKO_DEMO_KEY" >>/opt/ghostfolio/.env
fi

if [[ -n "${COINGECKO_PRO_KEY:-}" ]]; then
  echo "API_KEY_COINGECKO_PRO=$COINGECKO_PRO_KEY" >>/opt/ghostfolio/.env
fi
msg_ok "Set up Environment"

msg_info "Running Database Migrations"
cd /opt/ghostfolio
$STD npx prisma migrate deploy
$STD npx prisma db seed
msg_ok "Database Migrations Complete"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ghostfolio.service
[Unit]
Description=Ghostfolio Investment Tracker
After=network.target postgresql.service redis-server.service
Wants=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ghostfolio/dist/apps/api
Environment=NODE_ENV=production
EnvironmentFile=/opt/ghostfolio/.env
ExecStart=/usr/bin/node main.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now ghostfolio
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
