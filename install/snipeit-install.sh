#!/usr/bin/env bash


#Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE


source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  composer \
  git \
  sudo \
  mc \
  nginx \
  php8.2-{bcmath,common,ctype,curl,fileinfo,fpm,gd,iconv,intl,mbstring,mysql,soap,xml,xsl,zip,cli} \
  mariadb-server 
msg_ok "Installed Dependencies"

msg_info "Setting up database"
DB_NAME=snipeit_db
DB_USER=snipeit
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "SnipeIT-Credentials"
    echo "SnipeIT Database User: $DB_USER"
    echo "SnipeIT Database Password: $DB_PASS"
    echo "SnipeIT Database Name: $DB_NAME"
} >> ~/snipeit.creds
msg_ok "Set up database"

msg_info "Installing Snipe-IT"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
wget -q "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
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
$STD composer update --no-plugins --no-scripts
$STD composer install --no-dev --prefer-source --no-plugins --no-scripts

$STD php artisan key:generate --force
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
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
