#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  unzip \
  mariadb-server \
  apache2 \
  curl \
  sudo \
  php8.2-{mbstring,gd,fpm,curl,intl,ldap,tidy,bz2,mysql,zip,xml} \
  composer \
  libapache2-mod-php \
  make \
  mc
msg_ok "Installed Dependencies"

msg_info "Setting up Database"
DB_NAME=bookstack
DB_USER=bookstack
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD sudo mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "Bookstack-Credentials"
    echo "Bookstack Database User: $DB_USER"
    echo "Bookstack Database Password: $DB_PASS"
    echo "Bookstack Database Name: $DB_NAME"
} >> ~/bookstack.creds
msg_ok "Set up database"

msg_info "Setup Bookstack (Patience)"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/BookStackApp/BookStack/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/BookStackApp/BookStack/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv BookStack-${RELEASE} /opt/bookstack
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
$STD a2enmod php8.2
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Bookstack"

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
rm -rf /opt/v${RELEASE}.zip
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
