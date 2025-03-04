#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.monicahq.com/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg2\
  mariadb-server \
  apache2 \
  libapache2-mod-php \
  php-{bcmath,curl,dom,gd,gmp,iconv,intl,json,mbstring,mysqli,opcache,pdo-mysql,redis,tokenizer,xml,zip} \
  composer
msg_ok "Installed Dependencies"

msg_info "Setting up MariaDB"
DB_NAME=monica
DB_USER=monica
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "monica-Credentials"
    echo "monica Database User: $DB_USER"
    echo "monica Database Password: $DB_PASS"
    echo "monica Database Name: $DB_NAME"
} >> ~/monica.creds
msg_ok "Set up MariaDB"

msg_info "Setting up Node.js/Yarn"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g npm@latest
$STD npm install -g yarn
msg_ok "Installed Node.js/Yarn"

msg_info "Installing monica"
RELEASE=$(curl -s https://api.github.com/repos/monicahq/monica/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q "https://github.com/monicahq/monica/releases/download/v${RELEASE}/monica-v${RELEASE}.tar.bz2"
tar -xjf "monica-v${RELEASE}.tar.bz2"
mv "/opt/monica-v${RELEASE}" /opt/monica
cd /opt/monica
cp /opt/monica/.env.example /opt/monica/.env
HASH_SALT=$(openssl rand -base64 32)
sed -i -e "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" \
       -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" \
       -e "s|^HASH_SALT=.*|HASH_SALT=${HASH_SALT}|" \
       /opt/monica/.env
$STD composer install --no-dev -o --no-interaction
$STD yarn install
$STD yarn run production
$STD php artisan key:generate
$STD php artisan setup:production --email=admin@helper-scripts.com --password=helper-scripts.com --force
chown -R www-data:www-data /opt/monica
chmod -R 775 /opt/monica/storage
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed monica"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/monica.conf
<VirtualHost *:80>
    ServerName monica
    DocumentRoot /opt/monica/public
    <Directory /opt/monica/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/monica_error.log
    CustomLog /var/log/apache2/monica_access.log combined
</VirtualHost>
EOF
$STD a2ensite monica
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/monica-v${RELEASE}.tar.bz2"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
