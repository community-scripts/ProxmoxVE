#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://chevereto.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  exiftran \
  libimage-exiftool-perl
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_FPM="YES" PHP_UPLOAD_MAX_FILESIZE="512M" PHP_POST_MAX_SIZE="512M" PHP_MAX_EXECUTION_TIME="600" setup_php
setup_composer
setup_mariadb
setup_ffmpeg
MARIADB_DB_NAME="chevereto" MARIADB_DB_USER="chevereto" setup_mariadb_db

fetch_and_deploy_gh_release "chevereto" "chevereto/chevereto" "tarball"

msg_info "Installing Chevereto Dependencies"
cd /opt/chevereto/app
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
msg_ok "Installed Chevereto Dependencies"

msg_info "Configuring Chevereto"
cat <<EOF >/opt/chevereto/app/env.php
<?php

return [
    'CHEVERETO_DB_HOST' => 'localhost',
    'CHEVERETO_DB_PORT' => '3306',
    'CHEVERETO_DB_NAME' => '${MARIADB_DB_NAME}',
    'CHEVERETO_DB_USER' => '${MARIADB_DB_USER}',
    'CHEVERETO_DB_PASS' => '${MARIADB_DB_PASS}',
    'CHEVERETO_DB_TABLE_PREFIX' => 'chv_',
    'CHEVERETO_HOSTNAME' => '${LOCAL_IP}',
];
EOF
chown -R www-data:www-data /opt/chevereto
chmod -R 775 /opt/chevereto/images /opt/chevereto/content
msg_ok "Configured Chevereto"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/chevereto
server {
    listen 80;
    server_name _;
    root /opt/chevereto;
    index index.php;

    charset utf-8;
    client_max_body_size 512M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~* ^/images/.+\.(gif|jpe?g|png|bmp|webp)$ {
        try_files $uri =404;
    }

    location = /index.php {
        include fastcgi_params;
        fastcgi_pass unix:__PHP_FPM_SOCK__;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        fastcgi_read_timeout 600;
    }

    location ~ \.php$ {
        deny all;
    }

    location ^~ /app/ {
        deny all;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
sed -i "s|__PHP_FPM_SOCK__|$(get_php_fpm_socket)|" /etc/nginx/sites-available/chevereto
nginx_enable_site chevereto
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
