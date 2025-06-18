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
$STD apt-get install -y \
  composer \
  git \
  nginx \
  php8.2-{bcmath,common,ctype,curl,fileinfo,fpm,gd,iconv,intl,mbstring,mysql,soap,xml,xsl,zip,cli}
msg_ok "Installed Dependencies"

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

msg_info "Installing Snipe-IT"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar zxf $temp_file
mv snipe-it-${RELEASE} /opt/snipe-it
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
#$STD composer update --no-plugins --no-scripts
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed SnipeIT"

msg_info "Creating Service"
cat <<EOF >/etc/nginx/conf.d/snipeit.conf
server {
        listen 80;
        root /opt/snipe-it/public;
        server_name $IPADDRESS;
        index index.php;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php\$ {
                include fastcgi.conf;
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php8.2-fpm.sock;
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
        }
}
EOF

systemctl reload nginx
msg_ok "Configured Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
