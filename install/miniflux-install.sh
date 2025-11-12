#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: omernaveedxyz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://miniflux.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os


PG_VERSION=17 setup_postgresql
DB_NAME=miniflux
DB_USER=miniflux
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;"
msg_ok "Set up PostgreSQL database"

fetch_and_deploy_gh_release "miniflux" "miniflux/v2" "binary" "latest"


msg_info "Configuring Miniflux"
ADMIN_NAME=admin
ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
cat <<EOF >/etc/miniflux.conf
# See https://miniflux.app/docs/configuration.html
DATABASE_URL=user=$DB_USER password=$DB_PASS dbname=$DB_NAME sslmode=disable
CREATE_ADMIN=1
ADMIN_USERNAME=$ADMIN_NAME
ADMIN_PASSWORD=$ADMIN_PASS
LISTEN_ADDR=0.0.0.0:8080
EOF
{
  echo "Application Credentials"
  echo "DB_NAME: $DB_NAME"
  echo "DB_USER: $DB_USER"
  echo "DB_PASS: $DB_PASS"
  echo "ADMIN_USERNAME: $ADMIN_NAME"
  echo "ADMIN_PASSWORD: $ADMIN_PASS"
} >>~/miniflux.creds

$STD miniflux -migrate -config-file /etc/miniflux.conf

systemctl enable -q --now miniflux
msg_ok "Configured Miniflux"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
