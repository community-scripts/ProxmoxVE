#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  redis \
  jq \
  make
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/docmost/docmost/main/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
PG_VERSION="16" setup_postgresql
fetch_and_deploy_gh_release "docmost" "docmost/docmost"

msg_info "Setting up PostgreSQL"
DB_NAME="docmost_db"
DB_USER="docmost_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "Docmost-Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
} >>~/docmost.creds
msg_ok "Set up PostgreSQL"

msg_info "Configuring Docmost (Patience)"
cd /opt/docmost
mv .env.example .env
mkdir data
sed -i -e "s|APP_SECRET=.*|APP_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)|" \
  -e "s|DATABASE_URL=.*|DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME|" \
  -e "s|FILE_UPLOAD_SIZE_LIMIT=.*|FILE_UPLOAD_SIZE_LIMIT=50mb|" \
  /opt/docmost/.env
export NODE_OPTIONS="--max-old-space-size=2048"
$STD pnpm install
$STD pnpm build
msg_ok "Configured Docmost"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/docmost.service
[Unit]
Description=Docmost Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/docmost
ExecStart=/usr/bin/pnpm start
Restart=always
EnvironmentFile=/opt/docmost/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now docmost
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
