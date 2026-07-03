#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/LycheeOrg/Lychee

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  caddy \
  libimage-exiftool-perl \
  jpegoptim
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="bcmath,ldap,exif,gd,intl,imagick,redis,zip,pdo_pgsql,pcntl" setup_php
PG_VERSION="16" setup_postgresql
PG_DB_NAME="lychee" PG_DB_USER="lychee" setup_postgresql_db
setup_ffmpeg
setup_imagemagick

fetch_and_deploy_gh_release "lychee" "LycheeOrg/Lychee" "prebuild" "latest" "/opt/lychee" "Lychee.zip"

msg_info "Configuring Application"
cd /opt/lychee
cp .env.example .env
APP_KEY=$($STD php artisan key:generate --show)
sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env
sed -i "s|^APP_ENV=.*|APP_ENV=production|" .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|^APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=pgsql|" .env
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" .env
sed -i "s|^DB_PORT=.*|DB_PORT=5432|" .env
sed -i "s|^#\?DB_DATABASE=.*|DB_DATABASE=${PG_DB_NAME}|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${PG_DB_USER}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${PG_DB_PASS}|" .env
mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache public/dist public/uploads public/sym
touch public/dist/user.css public/dist/custom.js
chmod -R 775 storage bootstrap/cache public/dist public/uploads public/sym
msg_ok "Configured Application"

msg_info "Running Database Migrations"
cd /opt/lychee
$STD php artisan migrate --force
msg_ok "Ran Database Migrations"

chown -R www-data:www-data /opt/lychee

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/lychee/public
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
