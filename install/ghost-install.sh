#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: fabrice1236
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghost.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  nginx \
  ca-certificates \
  libjemalloc2
msg_ok "Installed Dependencies"

setup_mariadb

msg_info "Configuring Database"
DB_NAME=ghost
DB_USER=ghostuser
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Ghost-Credentials"
  echo "Ghost Database User: $DB_USER"
  echo "Ghost Database Password: $DB_PASS"
  echo "Ghost Database Name: $DB_NAME"
} >>~/ghost.creds
msg_ok "Configured MariaDB"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Ghost CLI"
$STD npm install ghost-cli@latest -g
msg_ok "Installed Ghost CLI"

msg_info "Creating Service"
$STD adduser --disabled-password --gecos "Ghost user" ghost-user
$STD usermod -aG sudo ghost-user
echo "ghost-user ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ghost-user
mkdir -p /var/www/ghost
chown -R ghost-user:ghost-user /var/www/ghost
chmod 775 /var/www/ghost
$STD sudo -u ghost-user -H sh -c "cd /var/www/ghost && ghost install --db=mysql --dbhost=localhost --dbuser=$DB_USER --dbpass=$DB_PASS --dbname=ghost --url=http://localhost:2368 --no-prompt --no-setup-nginx --no-setup-ssl --no-setup-mysql --enable --start --ip 0.0.0.0"
rm /etc/sudoers.d/ghost-user
msg_ok "Creating Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
$STD apt-get -y clean
msg_ok "Cleaned"
