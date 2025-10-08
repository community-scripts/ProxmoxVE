#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn,node-gyp" setup_nodejs
PG_VERSION="17" setup_postgresql
fetch_and_deploy_gh_release "wikijs" "requarks/wiki" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

msg_info "Set up PostgreSQL"
DB_NAME="wiki"
DB_USER="wikijs_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" $DB_NAME
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "WikiJS-Credentials"
  echo "WikiJS Database User: $DB_USER"
  echo "WikiJS Database Password: $DB_PASS"
  echo "WikiJS Database Name: $DB_NAME"
} >>~/wikijs.creds
msg_ok "Set up PostgreSQL"

msg_info "Configuring Wiki.js"
mv /opt/wikijs/config.sample.yml /opt/wikijs/config.yml
sed -i -E 's|^( *user: ).*|\1'"$DB_USER"'|' /opt/wikijs/config.yml
sed -i -E 's|^( *pass: ).*|\1'"$DB_PASS"'|' /opt/wikijs/config.yml
msg_ok "Configured Wiki.js"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wikijs.service
[Unit]
Description=Wiki.js
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/wikijs

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wikijs
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
