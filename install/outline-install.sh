#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/outline/outline

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  mkcert \
  git \
  redis
msg_ok "Installed Dependencies"

NODE_VERSION="20" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="16" setup_postgresql

msg_info "Set up PostgreSQL Database"
DB_NAME="outline"
DB_USER="outline"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "Outline-Credentials"
  echo "Outline Database User: $DB_USER"
  echo "Outline Database Password: $DB_PASS"
  echo "Outline Database Name: $DB_NAME"
} >>~/outline.creds
msg_ok "Set up PostgreSQL Database"

fetch_and_deploy_gh_release "outline" "outline/outline" "tarball"

msg_info "Configuring Outline (Patience)"
SECRET_KEY="$(openssl rand -hex 32)"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
cd /opt/outline
cp .env.sample .env
export NODE_ENV=development
sed -i 's/NODE_ENV=production/NODE_ENV=development/g' /opt/outline/.env
sed -i "s/generate_a_new_key/${SECRET_KEY}/g" /opt/outline/.env
sed -i "s/user:pass@postgres/${DB_USER}:${DB_PASS}@localhost/g" /opt/outline/.env
sed -i 's/redis:6379/localhost:6379/g' /opt/outline/.env
sed -i "5s#URL=#URL=http://${LOCAL_IP}#g" /opt/outline/.env
sed -i 's/FORCE_HTTPS=true/FORCE_HTTPS=false/g' /opt/outline/.env
export NODE_OPTIONS="--max-old-space-size=3584"
$STD yarn install --frozen-lockfile
export NODE_ENV=production
sed -i 's/NODE_ENV=development/NODE_ENV=production/g' /opt/outline/.env
$STD yarn build
msg_ok "Configured Outline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/outline.service
[Unit]
Description=Outline Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/outline
ExecStart=/usr/bin/yarn start
Restart=always
EnvironmentFile=/opt/outline/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now outline
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
