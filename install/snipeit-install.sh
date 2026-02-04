#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snipeitapp.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  nginx
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="ldap,soap,xsl" setup_php
setup_composer
fetch_and_deploy_gh_release "snipe-it" "grokability/snipe-it" "tarball"
setup_mariadb
MARIADB_DB_NAME="snipeit_db" MARIADB_DB_USER="snipeit" setup_mariadb_db

msg_info "Configuring Snipe-IT"
cd /opt/snipe-it
cp .env.example .env
sed -i -e "s|^APP_URL=.*|APP_URL=http://$LOCAL_IP|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=$MARIADB_DB_NAME|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=$MARIADB_DB_USER|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$MARIADB_DB_PASS|" .env
chown -R www-data: /opt/snipe-it
chmod -R 755 /opt/snipe-it
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
msg_ok "Configured Snipe-IT"

msg_info "Creating Service"
cat <<EOF >/etc/nginx/conf.d/snipeit.conf
server {
        listen 80;
        root /opt/snipe-it/public;
        server_name $LOCAL_IP;
        client_max_body_size 100M;
        index index.php;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php\$ {
                include fastcgi.conf;
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php8.3-fpm.sock;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
        }
}
EOF
systemctl reload nginx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
