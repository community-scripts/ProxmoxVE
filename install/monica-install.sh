#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PHP_VERSION="8.2" PHP_APACHE="YES" PHP_MODULE="mysqli,pdo-mysql" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="monica" MARIADB_DB_USER="monica" setup_mariadb_db
NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
fetch_and_deploy_gh_release "monica" "monicahq/monica" "prebuild" "latest" "/opt/monica" "monica-v*.tar.bz2"

msg_info "Configuring monica"
cd /opt/monica
cp /opt/monica/.env.example /opt/monica/.env
HASH_SALT=$(openssl rand -base64 32)
sed -i -e "s|^DB_USERNAME=.*|DB_USERNAME=${MARIADB_DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${MARIADB_DB_PASS}|" \
  -e "s|^HASH_SALT=.*|HASH_SALT=${HASH_SALT}|" \
  /opt/monica/.env
$STD composer install --no-dev -o --no-interaction
$STD yarn config set ignore-engines true
$STD yarn install
$STD yarn run production
$STD php artisan key:generate
$STD php artisan setup:production --email=admin@helper-scripts.com --password=helper-scripts.com --force
chown -R www-data:www-data /opt/monica
chmod -R 775 /opt/monica/storage
echo "* * * * * root php /opt/monica/artisan schedule:run >> /dev/null 2>&1" >>/etc/crontab
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
cleanup_lxc
