#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://yourls.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="yourls" MARIADB_DB_USER="yourls" setup_mariadb_db
PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="mysql,mbstring,gd,xml,curl" setup_php

fetch_and_deploy_gh_release "yourls" "YOURLS/YOURLS" "tarball"

msg_info "Configuring YOURLS"
COOKIEKEY=$(openssl rand -hex 24)
YOURLS_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-16)
cat <<EOF >/opt/yourls/user/config.php
<?php
define( 'YOURLS_DB_USER', '${MARIADB_DB_USER}' );
define( 'YOURLS_DB_PASS', '${MARIADB_DB_PASS}' );
define( 'YOURLS_DB_NAME', '${MARIADB_DB_NAME}' );
define( 'YOURLS_DB_HOST', 'localhost' );
define( 'YOURLS_DB_PREFIX', 'yourls_' );
define( 'YOURLS_SITE', 'http://${LOCAL_IP}' );
define( 'YOURLS_LANG', '' );
define( 'YOURLS_UNIQUE_URLS', true );
define( 'YOURLS_PRIVATE', true );
define( 'YOURLS_COOKIEKEY', '${COOKIEKEY}' );
\$yourls_user_passwords = [
    'admin' => '${YOURLS_PASS}',
];
define( 'YOURLS_URL_CONVERT', 36 );
define( 'YOURLS_DEBUG', false );
EOF
chown -R www-data:www-data /opt/yourls
msg_ok "Configured YOURLS"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/yourls
server {
    listen 80 default_server;
    server_name _;
    root /opt/yourls;
    index index.php;

    location / {
        try_files \$uri \$uri/ /yourls-loader.php\$is_args\$args;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~* \.(jpg|jpeg|gif|css|png|js|ico|woff|woff2)\$ {
        access_log off;
        expires max;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -sf /etc/nginx/sites-available/yourls /etc/nginx/sites-enabled/yourls
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
