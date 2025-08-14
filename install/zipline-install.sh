#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/diced/zipline

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
PG_VERSION="16" setup_postgresql
fetch_and_deploy_gh_release "zipline" "diced/zipline" "tarball"

msg_info "Setting up PostgreSQL"
DB_NAME=ziplinedb
DB_USER=zipline
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
SECRET_KEY="$(openssl rand -base64 42 | tr -dc 'a-zA-Z0-9')"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "Zipline-Credentials"
  echo "Zipline Database User: $DB_USER"
  echo "Zipline Database Password: $DB_PASS"
  echo "Zipline Database Name: $DB_NAME"
  echo "Zipline Secret Key: $SECRET_KEY"
} >>~/zipline.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Zipline (Patience)"
cd /opt/zipline
cat <<EOF >/opt/zipline/.env
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
CORE_SECRET=$SECRET_KEY
CORE_HOSTNAME=0.0.0.0
CORE_PORT=3000
CORE_RETURN_HTTPS=false
DATASOURCE_TYPE=local
DATASOURCE_LOCAL_DIRECTORY=/opt/zipline-uploads
EOF
mkdir -p /opt/zipline-uploads
$STD pnpm install
$STD pnpm build
msg_ok "Installed Zipline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zipline.service
[Unit]
Description=Zipline Service
After=network.target

[Service]
WorkingDirectory=/opt/zipline
ExecStart=/usr/bin/pnpm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zipline
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
