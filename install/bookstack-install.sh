#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

msg_info "Installing Dependencies"
$STD apt install -y make
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="ldap,tidy,mysqli" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="bookstack_db" MARIADB_DB_USER="bookstack_user" setup_mariadb_db

fetch_and_deploy_gh_release "bookstack" "BookStackApp/BookStack" "tarball"

msg_info "Configuring Bookstack (Patience)"
cd /opt/bookstack
cp .env.example .env
sudo sed -i "s|APP_URL=.*|APP_URL=http://$LOCAL_IP|g" /opt/bookstack/.env
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$MARIADB_DB_NAME/" /opt/bookstack/.env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$MARIADB_DB_USER/" /opt/bookstack/.env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MARIADB_DB_PASS/" /opt/bookstack/.env
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
cleanup_lxc
