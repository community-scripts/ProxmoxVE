#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BookStackApp/BookStack

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  apache2 \
  make
msg_ok "Installed Dependencies"

PHP_MODULE="ldap,tidy,bz2,mysqli" PHP_FPM="YES" PHP_APACHE="YES" PHP_VERSION="8.3" setup_php

setup_composer
setup_mariadb

msg_info "Setting up Database"
DB_NAME=bookstack
DB_USER=bookstack
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Bookstack-Credentials"
  echo "Bookstack Database User: $DB_USER"
  echo "Bookstack Database Password: $DB_PASS"
  echo "Bookstack Database Name: $DB_NAME"
} >>~/bookstack.creds
msg_ok "Set up database"

fetch_and_deploy_gh_release "bookstack" "BookStackApp/BookStack"
LOCAL_IP="$(hostname -I | awk '{print $1}')"

msg_info "Configuring Bookstack (Patience)"
cd /opt/bookstack
cp .env.example .env
sudo sed -i "s|APP_URL=.*|APP_URL=http://$LOCAL_IP|g" /opt/bookstack/.env
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" /opt/bookstack/.env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" /opt/bookstack/.env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" /opt/bookstack/.env
$STD composer install --no-dev --no-plugins --no-interaction
$STD php artisan key:generate --no-interaction --force
$STD php artisan migrate --no-interaction --force
chown www-data:www-data -R /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
chmod -R 755 /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
chmod -R 775 /opt/bookstack/storage /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads
chmod -R 640 /opt/bookstack/.env
$STD a2enmod rewrite
$STD a2enmod php8.3
msg_ok "Configured Bookstack"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/bookstack.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/bookstack/public/

  <Directory /opt/bookstack/public/>
      Options -Indexes +FollowSymLinks
      AllowOverride None
      Require all granted
      <IfModule mod_rewrite.c>
          <IfModule mod_negotiation.c>
              Options -MultiViews -Indexes
          </IfModule>

          RewriteEngine On

          # Handle Authorization Header
          RewriteCond %{HTTP:Authorization} .
          RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

          # Redirect Trailing Slashes If Not A Folder...
          RewriteCond %{REQUEST_FILENAME} !-d
          RewriteCond %{REQUEST_URI} (.+)/$
          RewriteRule ^ %1 [L,R=301]

          # Handle Front Controller...
          RewriteCond %{REQUEST_FILENAME} !-d
          RewriteCond %{REQUEST_FILENAME} !-f
          RewriteRule ^ index.php [L]
      </IfModule>
  </Directory>
  
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
$STD a2ensite bookstack.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
