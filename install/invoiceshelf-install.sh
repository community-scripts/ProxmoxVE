#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://invoiceshelf.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y caddy
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULES="bcmath,gd,intl,xml,zip,pdo_pgsql,mbstring,curl,exif" setup_php
setup_composer
NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="invoiceshelf" PG_DB_USER="invoiceshelf" setup_postgresql_db

fetch_and_deploy_gh_release "invoiceshelf" "InvoiceShelf/InvoiceShelf" "tarball"

msg_info "Setting up InvoiceShelf"
cd /opt/invoiceshelf
cp .env.example .env
sed -i "s|^APP_ENV=.*|APP_ENV=production|" .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|^APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=pgsql|" .env
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" .env
sed -i "s|^DB_PORT=.*|DB_PORT=5432|" .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${PG_DB_NAME}|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${PG_DB_USER}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${PG_DB_PASS}|" .env
COMPOSER_ALLOW_SUPERUSER=1 $STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
if command -v corepack >/dev/null 2>&1; then
  $STD corepack enable
  $STD corepack pnpm install
  $STD corepack pnpm run build
else
  $STD pnpm install
  $STD pnpm run build
fi
mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache
chown -R www-data:www-data /opt/invoiceshelf
chmod -R 775 storage bootstrap/cache
$STD php artisan migrate --force
$STD php artisan storage:link
msg_ok "Set up InvoiceShelf"

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/invoiceshelf/public
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
    encode gzip
}
EOF
usermod -aG www-data caddy
msg_ok "Configured Caddy"

systemctl enable -q --now php${PHP_VER}-fpm
systemctl restart caddy

motd_ssh
customize
cleanup_lxc
