#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koillection.github.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="16" setup_postgresql
PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="apcu,ctype,dom,fileinfo,iconv,pgsql" setup_php
setup_composer

msg_info "Setting up PostgreSQL"
DB_NAME=koillection
DB_USER=koillection
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
  echo "Koillection Credentials"
  echo "Koillection Database User: $DB_USER"
  echo "Koillection Database Password: $DB_PASS"
  echo "Koillection Database Name: $DB_NAME"
} >>~/koillection.creds
msg_ok "Set up PostgreSQL"

fetch_and_deploy_gh_release "koillection" "benjaminjonard/koillection"

msg_info "Configuring Koillection"
cd /opt/koillection
cp /opt/koillection/.env /opt/koillection/.env.local
APP_SECRET=$(openssl rand -base64 32)
sed -i -e "s|^APP_ENV=.*|APP_ENV=prod|" \
  -e "s|^APP_DEBUG=.*|APP_DEBUG=0|" \
  -e "s|^APP_SECRET=.*|APP_SECRET=${APP_SECRET}|" \
  -e "s|^DB_NAME=.*|DB_NAME=${DB_NAME}|" \
  -e "s|^DB_USER=.*|DB_USER=${DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" \
  /opt/koillection/.env.local
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev -o --no-interaction --classmap-authoritative
$STD php bin/console doctrine:migrations:migrate --no-interaction
$STD php bin/console app:translations:dump
cd assets/
$STD yarn install
$STD yarn build
chown -R www-data:www-data /opt/koillection/public/uploads
msg_ok "Configured Koillection"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/koillection.conf
<VirtualHost *:80>
    ServerName koillection
    DocumentRoot /opt/koillection/public
    <Directory /opt/koillection/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php/\$1 [L]
    </Directory>

    ErrorLog /var/log/apache2/koillection_error.log
    CustomLog /var/log/apache2/koillection_access.log combined
</VirtualHost>
EOF
$STD a2ensite koillection
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
