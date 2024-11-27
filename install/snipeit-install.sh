#!/usr/bin/env bash
#Copyright (c) 2021-2024 community-scripts ORG
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
$STD apt-get install -y curl
$STD apt-get install -y git
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y nginx
$STD apt-get install -y php8.2-{bcmath,common,ctype,curl,fileinfo,fpm,gd,iconv,intl,mbstring,mysql,soap,xml,xsl,zip,cli}
$STD apt-get install -y mariadb-server
msg_ok "Installed Dependencies"

msg_info "Installing Composer"
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
msg_ok "Installed Composer"

msg_ok "Configre Database\n"
read -r -p "Enter password for Database user: " password
echo -e 'CREATE DATABASE snipeit;' | mysql
echo -e "GRANT ALL ON snipeit.* TO snipeit@localhost identified by '$password';" | mysql
echo -e 'FLUSH PRIVILEGES;' | mysql
msg_ok "Configured Database"

msg_info "Clone SnipeIT from Github"
cd /var/www/html
git clone https://github.com/snipe/snipe-it snipe-it
msg_ok "Finished cloning"

msg_info "Configure SnipeIT"
cd snipe-it
cp .env.example .env
IPADDRESS=$(hostname -I | awk '{print $1}')
sed -i "s|^APP_URL=.*|APP_URL=http://$IPADDRESS|" .env

sed -i "s|^DB_DATABASE=.*|DB_DATABASE=snipeit|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=snipeit|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$password|" .env
chown -R www-data: /var/www/html/snipe-it
chmod -R 755 /var/www/html/snipe-it
git config --global --add safe.directory /var/www/html/snipe-it

msg_ok "Configred SnipeIT"

msg_info "Update SnipeIT dependencies"
export COMPOSER_ALLOW_SUPERUSER=1
composer update --no-plugins --no-scripts
composer install --no-dev --prefer-source --no-plugins --no-scripts
msg_ok "Update OK"

msg_info "Generate APP_KEY"
php artisan key:generate --force
msg_ok "Done"

msg_info "Configure NGINX"
echo -e '
server {
        listen 80;
        server_name '$IPADDRESS';
        root /var/www/html/snipe-it/public;
        
        index index.php;
                
        location / {
                try_files $uri $uri/ /index.php?$query_string;

        }
        
        location ~ \.php$ {
		include fastcgi.conf;
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php8.2-fpm.sock;
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        	include fastcgi_params;
        }
}' > /etc/nginx/conf.d/snipeit.conf
systemctl restart nginx
msg_ok "Configured NGINX"

msg_ok "SnipeIT is up and running, head to $IPADDRESS to reach the site"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
