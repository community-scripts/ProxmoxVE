#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Hosteroid/domain-monitor

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y --no-install-recommends \
  libicu-dev \
  libzip-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libfreetype6-dev \
  libxml2-dev \
  libcurl4-openssl-dev \
  libonig-dev \
  pkg-config
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="mysql" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="domain_monitor" MARIADB_DB_USER="domainmonitor" setup_mariadb_db
fetch_and_deploy_gh_release "domain-monitor" "Hosteroid/domain-monitor" "prebuild" "latest" "/opt/domain-monitor" "domain-monitor-v*.zip"

msg_info "Setting up Domain Monitor"
ENC_KEY=$(openssl rand -base64 32 | tr -d '\n')
cd /opt/domain-monitor
$STD composer install
cp env.example.txt .env
sed -i -e "s|^APP_ENV=.*|APP_ENV=production|" \
  -e "s|^APP_ENCRYPTION_KEY=.*|APP_ENCRYPTION_KEY=$ENC_KEY|" \
  -e "s|^SESSION_COOKIE_HTTPONLY=.*|SESSION_COOKIE_HTTPONLY=0|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=$MARIADB_DB_USER|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$MARIADB_DB_PASS|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=$MARIADB_DB_NAME|" .env
echo "0 0 * * * root /usr/bin/php /opt/domain-monitor/cron/check_domains.php" >>/etc/crontab

cat <<EOF >/etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:80>
    ServerName domainmonitor.local
    DocumentRoot "/opt/domain-monitor/public"

    <Directory "/opt/domain-monitor/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
chown -R www-data:www-data /opt/domain-monitor
$STD a2enmod rewrite headers
$STD systemctl reload apache2
msg_ok "Setup Domain Monitor"

motd_ssh
customize
cleanup_lxc
