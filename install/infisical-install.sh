#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://infisical.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  ca-certificates \
  redis
msg_ok "Installed Dependencies"

msg_info "Setting up Infisical repository"
curl -fsSL "https://artifacts-infisical-core.infisical.com/infisical.gpg" | gpg --dearmor >/etc/apt/trusted.gpg.d/infisical.gpg
cat <<EOF >/etc/apt/sources.list.d/infisical.sources
Types: deb
URIs: https://artifacts-infisical-core.infisical.com/deb
Suites: stable
Components: main
Signed-By: /etc/apt/trusted.gpg.d/infisical.gpg
EOF
msg_ok "Setup Infisical repository"

PG_VERSION="17" setup_postgresql

msg_info "Configuring PostgreSQL"
DB_NAME="infisical_db"
DB_USER="infisical"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "Infiscal Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
} >>~/infisical.creds
msg_ok "Configured PostgreSQL"

msg_info "Setting up Infisical"
IP_ADDR=$(hostname -I | awk '{print $1}')
$STD apt install -y infisical-core
mkdir -p /etc/infisical
cat <<EOF >/etc/infisical/infisical.rb
infisical_core['ENCRYPTION_KEY'] = '6c1fe4e407b8911c104518103505b218'
infisical_core['AUTH_SECRET'] = '5lrMXKKWCVocS/uerPsl7V+TX/aaUaI7iDkgl3tSmLE='
infisical_core['HOST'] = '$IP_ADDR'
infisical_core['DB_CONNECTION_URI'] = 'postgres://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}'
infisical_core['REDIS_URL'] = 'redis://localhost:6379'
EOF
$STD infisical-ctl reconfigure
msg_ok "Setup Infisical"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
