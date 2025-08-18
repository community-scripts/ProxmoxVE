#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://umami.is/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="16" setup_postgresql
fetch_and_deploy_gh_release "umami" "umami-software/umami" "tarball"

msg_info "Setting up postgresql"
DB_NAME=umamidb
DB_USER=umami
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
SECRET_KEY="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "Umami-Credentials"
  echo "Umami Database User: $DB_USER"
  echo "Umami Database Password: $DB_PASS"
  echo "Umami Database Name: $DB_NAME"
  echo "Umami Secret Key: $SECRET_KEY"
} >>~/umami.creds
msg_ok "Set up postgresql"

msg_info "Configuring Umami"
cd /opt/umami
$STD yarn install
echo -e "DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME" >>/opt/umami/.env
$STD yarn run build
msg_ok "Configured Umami"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/umami.service
[Unit]
Description=umami

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/umami
ExecStart=/usr/bin/yarn run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now umami
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
