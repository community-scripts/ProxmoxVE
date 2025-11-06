#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://joplinapp.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  rsync
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
NODE_VERSION=22 NODE_MODULE="yarn,npm,pm2" setup_nodejs
mkdir -p /opt/pm2
export PM2_HOME=/opt/pm2
$STD pm2 install pm2-logrotate
$STD pm2 set pm2-logrotate:max_size 100MB
$STD pm2 set pm2-logrotate:retain 5
$STD pm2 set pm2-logrotate:compress tr

msg_info "Setting up PostgreSQL Database"
DB_NAME=joplin
DB_USER=joplin
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "Joplin-Credentials"
  echo "Joplin Database User: $DB_USER"
  echo "Joplin Database Password: $DB_PASS"
  echo "Joplin Database Name: $DB_NAME"
} >>~/joplin.creds
msg_ok "Set up PostgreSQL Database"

fetch_and_deploy_gh_release "joplin-server" "laurent22/joplin" "tarball" "latest"

msg_info "Setting up Joplin Server (Patience)"
LOCAL_IP=$(hostname -I | awk '{print $1}')
cd /opt/joplin-server
sed -i "/onenote-converter/d" packages/lib/package.json
$STD yarn config set --home enableTelemetry 0
export BUILD_SEQUENCIAL=1
$STD yarn install --inline-builds

cat <<EOF >/opt/joplin-server/.env
PM2_HOME=/opt/pm2
NODE_ENV=production
APP_BASE_URL=http://$LOCAL_IP:22300
APP_PORT=22300
DB_CLIENT=pg
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DATABASE=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PORT=5432
POSTGRES_HOST=localhost
EOF
msg_ok "Setup Joplin Server"

msg_info "Setting up Service"
cat <<EOF >/etc/systemd/system/joplin-server.service
[Unit]
Description=Joplin Server Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/joplin-server/packages/server
EnvironmentFile=/opt/joplin-server/.env
ExecStart=/usr/bin/yarn start-prod
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now joplin-server
msg_ok "Service Setup"

motd_ssh
customize
cleanup_lxc
