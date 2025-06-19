#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plankanban/planka

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt-get install -y \
  unzip \
  build-essential \
  python3-venv
msg_ok "Installed dependencies"

NODE_VERSION="22" setup_nodejs
PG_VERSION="16" setup_postgresql

msg_info "Setting up PostgreSQL Database"
DB_NAME=planka
DB_USER=planka
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "PLANKA DB Credentials"
  echo "PLANKA Database User: $DB_USER"
  echo "PLANKA Database Password: $DB_PASS"
  echo "PLANKA Database Name: $DB_NAME"
} >>~/planka.creds
msg_ok "Set up PostgreSQL Database"

fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"

msg_info "Configuring PLANKA"
LOCAL_IP=$(hostname -I | awk '{print $1}')
SECRET_KEY=$(openssl rand -hex 64)
cd /opt/planka/planka
$STD npm install
cp .env.sample .env
sed -i "s#http://localhost:1337#http://$LOCAL_IP:1337#g" /opt/planka/planka/.env
sed -i "s#postgres@localhost#planka:$DB_PASS@localhost#g" /opt/planka/planka/.env
sed -i "s#notsecretkey#$SECRET_KEY#g" /opt/planka/planka/.env
$STD npm run db:init
msg_ok "Configured PLANKA"

msg_info "Creating Admin User"
ADMIN_EMAIL="admin@planka.local"
ADMIN_PASSWORD="$(openssl rand -base64 12)"
ADMIN_NAME="Administrator"
ADMIN_USERNAME="admin"
echo "" >>.env
echo "# Temporary admin user creation settings" >>.env
echo "DEFAULT_ADMIN_EMAIL=$ADMIN_EMAIL" >>.env
echo "DEFAULT_ADMIN_PASSWORD=$ADMIN_PASSWORD" >>.env
echo "DEFAULT_ADMIN_NAME=$ADMIN_NAME" >>.env
echo "DEFAULT_ADMIN_USERNAME=$ADMIN_USERNAME" >>.env
$STD npm run db:seed
sed -i '/# Temporary admin user creation settings/,$d' .env
{
  echo ""
  echo "PLANKA Admin Credentials"
  echo "Admin Email: $ADMIN_EMAIL"
  echo "Admin Password: $ADMIN_PASSWORD"
  echo "Admin Name: $ADMIN_NAME"
  echo "Admin Username: $ADMIN_USERNAME"
} >>~/planka.creds
msg_ok "Created Admin User"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/planka.service
[Unit]
Description=planka Service
After=network.target

[Service]
WorkingDirectory=/opt/planka/planka
ExecStart=/usr/bin/npm start --prod
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now planka
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
