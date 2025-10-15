#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

PHP_VERSION="8.3" PHP_MODULE="common,ctype,ldap,fileinfo,iconv,mysql,soap,xsl" PHP_FPM="YES" setup_php
setup_composer
fetch_and_deploy_gh_release "snipe-it" "snipe/snipe-it" "tarball"
setup_mariadb

msg_info "Setting up database"
DB_NAME=snipeit_db
DB_USER=snipeit
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "SnipeIT-Credentials"
  echo "SnipeIT Database User: $DB_USER"
  echo "SnipeIT Database Password: $DB_PASS"
  echo "SnipeIT Database Name: $DB_NAME"
} >>~/snipeit.creds
msg_ok "Set up database"

msg_info "Configuring Snipe-IT"
cd /opt/snipe-it
cp .env.example .env
IPADDRESS=$(hostname -I | awk '{print $1}')

sed -i -e "s|^APP_URL=.*|APP_URL=http://$IPADDRESS|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=$DB_USER|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

chown -R www-data: /opt/snipe-it
chmod -R 755 /opt/snipe-it
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
msg_ok "Configured SnipeIT"

msg_info "Creating Service"
cat <<EOF >/etc/nginx/conf.d/snipeit.conf
server {
        listen 80;
        root /opt/snipe-it/public;
        server_name $IPADDRESS;
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

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
