#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="firefly" MARIADB_DB_USER="firefly" setup_mariadb_db

fetch_and_deploy_gh_release "firefly" "firefly-iii/firefly-iii" "prebuild" "latest" "/opt/firefly" "FireflyIII-*.zip"
fetch_and_deploy_gh_release "dataimporter" "firefly-iii/data-importer" "prebuild" "latest" "/opt/firefly/dataimporter" "DataImporter-v*.tar.gz"

msg_info "Configuring Firefly III (Patience)"
chown -R www-data:www-data /opt/firefly
chmod -R 775 /opt/firefly/storage
cd /opt/firefly
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=localhost/" /opt/firefly/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MARIADB_DB_PASS/" /opt/firefly/.env
$STD composer install --no-dev --no-plugins --no-interaction
$STD php artisan firefly:upgrade-database
$STD php artisan firefly:correct-database
$STD php artisan firefly:report-integrity
$STD php artisan firefly:laravel-passport-keys
msg_ok "Configured Firefly III"

msg_info "Configuring Data Importer"
cp /opt/firefly/dataimporter/.env.example /opt/firefly/dataimporter/.env
sed -i "s#FIREFLY_III_URL=#FIREFLY_III_URL=http://${LOCAL_IP}#g" /opt/firefly/dataimporter/.env
chown -R www-data:www-data /opt/firefly
msg_ok "Configured Data Importer"

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
  
  RedirectMatch 301 ^/dataimporter$ /dataimporter/

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
cleanup_lxc
