#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: jkrgr0
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.2fauth.app/

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

export PHP_VERSION="8.4"
PHP_FPM="YES" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="2fauth_db" MARIADB_DB_USER="2fauth" setup_mariadb_db

fetch_and_deploy_gh_release "2fauth" "Bubka/2FAuth" "tarball"

msg_info "Setup 2FAuth"
cd /opt/2fauth
cp .env.example .env
sed -i -e "s|^APP_URL=.*|APP_URL=http://$LOCAL_IP|" \
  -e "s|^DB_CONNECTION=$|DB_CONNECTION=mysql|" \
  -e "s|^DB_DATABASE=$|DB_DATABASE=$MARIADB_DB_NAME|" \
  -e "s|^DB_HOST=$|DB_HOST=127.0.0.1|" \
  -e "s|^DB_PORT=$|DB_PORT=3306|" \
  -e "s|^DB_USERNAME=$|DB_USERNAME=$MARIADB_DB_USER|" \
  -e "s|^DB_PASSWORD=$|DB_PASSWORD=$MARIADB_DB_PASS|" .env
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer update --no-plugins --no-scripts
$STD composer install --no-dev --prefer-dist --no-plugins --no-scripts
$STD php artisan key:generate --force
$STD php artisan migrate:refresh
$STD php artisan passport:install -q -n
$STD php artisan storage:link
$STD php artisan config:cache
chown -R www-data: /opt/2fauth
chmod -R 755 /opt/2fauth
msg_ok "Setup 2fauth"

msg_info "Configure Service"
cat <<EOF >/etc/nginx/conf.d/2fauth.conf
server {
        listen 80;
        root /opt/2fauth/public;
        server_name $LOCAL_IP;
        index index.php;
        charset utf-8;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt { access_log off; log_not_found off; }

        error_page 404 /index.php;

        location ~ \.php\$ {
                fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
                fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
                include fastcgi_params;
        }

        location ~ /\.(?!well-known).* {
                deny all;
        }
}
EOF
systemctl reload nginx
msg_ok "Configured Service"

motd_ssh
customize
cleanup_lxc
