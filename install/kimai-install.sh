#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

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
  apache2 \
  git \
  expect
msg_ok "Installed Dependencies"

setup_mariadb
PHP_VERSION="8.4" PHP_MODULE="mysql" PHP_APACHE="YES" setup_php
setup_composer

msg_info "Setting up database"
DB_NAME=kimai_db
DB_USER=kimai
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
MYSQL_VERSION=$(mariadb --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
$STD mariadb -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Kimai-Credentials"
  echo "Kimai Database User: $DB_USER"
  echo "Kimai Database Password: $DB_PASS"
  echo "Kimai Database Name: $DB_NAME"
} >>~/kimai.creds
msg_ok "Set up database"

fetch_and_deploy_gh_release "kimai" "kimai/kimai"

msg_info "Setup Kimai"
cd /opt/kimai
echo "export COMPOSER_ALLOW_SUPERUSER=1" >>~/.bashrc
source ~/.bashrc
$STD composer install --no-dev --optimize-autoloader --no-interaction
cp .env.dist .env
sed -i "/^DATABASE_URL=/c\DATABASE_URL=mysql://$DB_USER:$DB_PASS@127.0.0.1:3306/$DB_NAME?charset=utf8mb4&serverVersion=mariadb-$MYSQL_VERSION" /opt/kimai/.env
$STD bin/console kimai:install -n
$STD expect <<EOF
set timeout -1
log_user 0

spawn bin/console kimai:user:create admin admin@helper-scripts.com ROLE_SUPER_ADMIN

expect "Please enter the password:"
send "helper-scripts.com\r"

expect eof
EOF
$STD composer update --no-interaction
cat <<EOF >/opt/kimai/config/packages/local.yaml
kimai:
    timesheet:
        rounding:
            default:
                begin: 15
                end: 15

EOF
msg_ok "Installed Kimai"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/kimai.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/kimai/public/

   <Directory /opt/kimai/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
  
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
$STD a2ensite kimai.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

msg_info "Setup Permissions"
chown -R :www-data /opt/*
chmod -R g+r /opt/*
chmod -R g+rw /opt/*
chown -R www-data:www-data /opt/*
chmod -R 777 /opt/*
msg_ok "Setup Permissions"

motd_ssh
customize
cleanup_lxc
