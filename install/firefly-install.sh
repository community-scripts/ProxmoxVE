#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: quantumryuu | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://firefly-iii.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="mysql" setup_php
setup_composer
setup_mariadb
LOCAL_IP=$(hostname -I | awk '{print $1}')

msg_info "Setting up database"
DB_NAME=firefly
DB_USER=firefly
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Firefly-Credentials"
  echo "Firefly Database User: $DB_USER"
  echo "Firefly Database Password: $DB_PASS"
  echo "Firefly Database Name: $DB_NAME"
} >>~/firefly.creds
msg_ok "Set up database"

fetch_and_deploy_gh_release "firefly" "firefly-iii/firefly-iii" "prebuild" "latest" "/opt/firefly" "FireflyIII-*.zip"

msg_info "Configuring Firefly III (Patience)"
chown -R www-data:www-data /opt/firefly
chmod -R 775 /opt/firefly/storage
cd /opt/firefly
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=localhost/" /opt/firefly/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" /opt/firefly/.env
$STD composer install --no-dev --no-plugins --no-interaction
$STD php artisan firefly:upgrade-database
$STD php artisan firefly:correct-database
$STD php artisan firefly:report-integrity
$STD php artisan firefly:laravel-passport-keys
IMPORTER_RELEASE=$(curl -fsSL https://api.github.com/repos/firefly-iii/data-importer/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
mkdir -p /opt/firefly/dataimporter
cd /opt
curl -fsSL "https://github.com/firefly-iii/data-importer/releases/download/v${IMPORTER_RELEASE}/DataImporter-v${IMPORTER_RELEASE}.tar.gz" -o "DataImporter-v${IMPORTER_RELEASE}.tar.gz"
tar -xzf "DataImporter-v${IMPORTER_RELEASE}.tar.gz" -C /opt/firefly/dataimporter
cp /opt/firefly/dataimporter/.env.example /opt/firefly/dataimporter/.env
sed -i "s#FIREFLY_III_URL=#FIREFLY_III_URL=http://${LOCAL_IP}#g" /opt/firefly/dataimporter/.env
chown -R www-data:www-data /opt/firefly
msg_ok "Configured Firefly III"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/firefly.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/firefly/public/

   <Directory /opt/firefly/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

  Alias /dataimporter/ /opt/firefly/dataimporter/public/

    <Directory /opt/firefly/dataimporter/public/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>

    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
chown www-data:www-data /opt/firefly/storage/oauth-*.key
$STD a2enmod php8.4
$STD a2enmod rewrite
$STD a2ensite firefly.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/DataImporter-v${IMPORTER_RELEASE}.tar.gz"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
