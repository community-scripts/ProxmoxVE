#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/opf/openproject

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
  ca-certificates
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql

msg_info "Setting up PostgreSQL"
DB_NAME=openproject
DB_USER=openproject
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
API_KEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
  echo "OpenProject-Credentials"
  echo -e "OpenProject Database User: $DB_USER"
  echo -e "OpenProject Database Password: $DB_PASS"
  echo -e "OpenProject Database Name: $DB_NAME"
  echo -e "OpenProject API Key: $API_KEY"
} >>~/openproject.creds
msg_ok "Set up PostgreSQL"

msg_info "Setting up OpenProject Repository"
curl -fsSL "https://dl.packager.io/srv/opf/openproject/key" | gpg --dearmor >/etc/apt/trusted.gpg.d/packager-io.gpg
curl -fsSL "https://dl.packager.io/srv/opf/openproject/stable/15/installer/debian/12.repo" -o "/etc/apt/sources.list.d/openproject.list"
$STD apt update
msg_ok "Setup OpenProject Repository"

msg_info "Installing OpenProject"
$STD apt install -y openproject
msg_ok "Installed OpenProject"

msg_info "Configuring OpenProject"
IP_ADDR=$(hostname -I | cut -d' ' -f1)
cat <<EOF >/etc/openproject/installer.dat
openproject/edition default

postgres/retry retry
postgres/autoinstall reuse
postgres/db_host 127.0.0.1
postgres/db_port 5432
postgres/db_username ${DB_USER}
postgres/db_password ${DB_PASS}
postgres/db_name ${DB_NAME}
server/autoinstall install
server/variant apache2

server/hostname ${IP_ADDR}
server/server_path_prefix /openproject
server/ssl no
server/variant apache2
repositories/api-key ${API_KEY}
repositories/svn-install skip
repositories/git-install install
repositories/git-path /var/db/openproject/git
repositories/git-http-backend /usr/lib/git-core/git-http-backend/
memcached/autoinstall install
openproject/admin_email admin@example.net
openproject/default_language en
EOF

$STD sudo openproject configure
msg_ok "Configured OpenProject"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
