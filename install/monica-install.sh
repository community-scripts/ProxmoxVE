#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.monicahq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.2" PHP_APACHE="YES" PHP_MODULE="dom,gmp,iconv,mysqli,pdo-mysql,redis,tokenizer" setup_php
setup_composer
setup_mariadb
NODE_VERSION="20" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Setting up MariaDB"
DB_NAME=monica
DB_USER=monica
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "monica-Credentials"
  echo "monica Database User: $DB_USER"
  echo "monica Database Password: $DB_PASS"
  echo "monica Database Name: $DB_NAME"
} >>~/monica.creds
msg_ok "Set up MariaDB"

fetch_and_deploy_gh_release "monica" "monicahq/monica" "prebuild" "latest" "/opt/monica" "monica-v*.tar.bz2"

msg_info "Configuring monica"
cd /opt/monica
cp /opt/monica/.env.example /opt/monica/.env
HASH_SALT=$(openssl rand -base64 32)
sed -i -e "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" \
  -e "s|^HASH_SALT=.*|HASH_SALT=${HASH_SALT}|" \
  /opt/monica/.env
$STD composer install --no-dev -o --no-interaction
$STD yarn install
$STD yarn run production
$STD php artisan key:generate
$STD php artisan setup:production --email=admin@helper-scripts.com --password=helper-scripts.com --force
chown -R www-data:www-data /opt/monica
chmod -R 775 /opt/monica/storage
msg_ok "Configured monica"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/monica.conf
<VirtualHost *:80>
    ServerName monica
    DocumentRoot /opt/monica/public
    <Directory /opt/monica/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/monica_error.log
    CustomLog /var/log/apache2/monica_access.log combined
</VirtualHost>
EOF
$STD a2ensite monica
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
