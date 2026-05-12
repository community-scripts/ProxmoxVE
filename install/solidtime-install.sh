#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.solidtime.io/

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

PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULES="bcmath,gd,intl,xml,zip,pdo_pgsql,redis,mbstring,curl" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="solidtime" PG_DB_USER="solidtime" setup_postgresql_db

fetch_and_deploy_gh_release "solidtime" "solidtime-io/solidtime" "tarball"

msg_info "Setting up SolidTime"
cd /opt/solidtime
cp .env.example .env
sed -i "s|^APP_ENV=.*|APP_ENV=production|" .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|^APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
sed -i "s|^APP_ENABLE_REGISTRATION=.*|APP_ENABLE_REGISTRATION=true|" .env
sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=pgsql|" .env
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" .env
sed -i "s|^DB_PORT=.*|DB_PORT=5432|" .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${PG_DB_NAME}|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${PG_DB_USER}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${PG_DB_PASS}|" .env
sed -i "s|^FILESYSTEM_DISK=.*|FILESYSTEM_DISK=local|" .env
sed -i "s|^PUBLIC_FILESYSTEM_DISK=.*|PUBLIC_FILESYSTEM_DISK=public|" .env
sed -i "s|^MAIL_MAILER=.*|MAIL_MAILER=log|" .env
sed -i "s|^SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=false|" .env
grep -q "^SESSION_SECURE_COOKIE=" .env || echo "SESSION_SECURE_COOKIE=false" >>.env
sed -i "s|^APP_FORCE_HTTPS=.*|APP_FORCE_HTTPS=false|" .env
grep -q "^APP_FORCE_HTTPS=" .env || echo "APP_FORCE_HTTPS=false" >>.env
$STD composer install --no-dev --optimize-autoloader
php artisan self-host:generate-keys >/tmp/solidtime.keys 2>/dev/null
while IFS= read -r line; do
  KEY="${line%%=*}"
  [[ -z "$KEY" || "${KEY:0:1}" == "#" ]] && continue
  sed -i "/^${KEY}=/d" .env
  echo "$line" >>.env
done </tmp/solidtime.keys
rm -f /tmp/solidtime.keys
$STD npm install
$STD npm run build
rm -rf node_modules
mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache
chown -R www-data:www-data /opt/solidtime
chmod -R 775 storage bootstrap/cache
$STD php artisan storage:link
$STD php artisan migrate --force
$STD php artisan passport:client --personal --name="API" -n
$STD php artisan optimize:clear
msg_ok "Set up SolidTime"

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/solidtime/public
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
    encode gzip
}
EOF
usermod -aG www-data caddy
systemctl enable -q --now php${PHP_VER}-fpm
systemctl restart caddy
msg_ok "Configured Caddy"

motd_ssh
customize
cleanup_lxc
