#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  zip \
  ca-certificates \
  software-properties-common \
  apt-transport-https \
  lsb-release \
  php \
  libapache2-mod-php \
  php-opcache \
  php-curl \
  php-gd \
  php-mbstring \
  php-xml \
  php-bcmath \
  php-intl \
  php-zip \
  php-xsl \
  php-pgsql \
  nodejs \
  composer \
  postgresql
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=partdb
DB_USER=partdb
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
echo "Part-DB Database Credentials"
echo -e "Part-DB Database User: \e[32m$DB_USER\e[0m"
echo -e "Part-DB Database Password: \e[32m$DB_PASS\e[0m"
echo -e "Part-DB Database Name: \e[32m$DB_NAME\e[0m"
echo ""
} >> ~/partdb.creds
msg_ok "Set up PostgreSQL"

msg_info "Install yarn"
  curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg |  gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
  echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" >/etc/apt/sources.list.d/yarn.list
  $STD apt-get update
  $STD apt-get install -y yarn
msg_ok "Installed yarn"

msg_info "Installing Part-DB (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/Part-DB/Part-DB-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/Part-DB/Part-DB-server/archive/refs/tags/v${RELEASE}.zip"
unzip -q "v${RELEASE}.zip"
mv /opt/Part-DB-server-${RELEASE}/ /var/www/partdb

cd /var/www/partdb/
cp .env .env.local
sed -i "s|DATABASE_URL=\"sqlite:///%kernel.project_dir%/var/app.db\"|DATABASE_URL=\"postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}?serverVersion=12.19&charset=utf8\"|" .env.local

chown -R www-data:www-data /var/www/partdb
$STD sudo -u www-data composer install --no-dev -o
$STD yarn install
$STD yarn build
$STD sudo -u www-data php bin/console cache:clear
sudo -u www-data php bin/console doctrine:migrations:migrate -n > ~/database-migration-output

ADMIN_PASS=$(grep -oP 'The initial password for the "admin" user is: \K\w+' ~/database-migration-output)
{
echo "Part-DB Admin Credentials"
echo -e "Part-DB Admin User: \e[32madmin\e[0m"
echo -e "Part-DB Admin User: \e[32m$ADMIN_PASS\e[0m"
} >> ~/partdb.creds

cat <<EOF >/etc/apache2/sites-available/partdb.conf
<VirtualHost *:80>
    ServerName partdb
    DocumentRoot /var/www/partdb/public
    <Directory /var/www/partdb/public>
        AllowOverride All
        Order Allow,Deny
        Allow from All
    </Directory>

    ErrorLog /var/log/apache2/partdb_error.log
    CustomLog /var/log/apache2/partdb_access.log combined
</VirtualHost>
EOF
$STD a2ensite partdb
$STD a2enmod rewrite
rm /etc/apache2/sites-enabled/000-default.conf
service apache2 restart
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Part-DB"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/database-migration-output
rm -rf "/opt/v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
