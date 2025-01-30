#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
  php-{opcache,curl,gd,mbstring,xml,bcmath,intl,zip,xsl,pgsql} \
  libapache2-mod-php \
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
echo "Part-DB Credentials"
echo "Part-DB Database User: $DB_USER"
echo "Part-DB Database Password: $DB_PASS"
echo "Part-DB Database Name: $DB_NAME"
} >> ~/partdb.creds
msg_ok "Set up PostgreSQL"

msg_info "Setting up Node.js/Yarn"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g npm@latest
$STD npm install -g yarn
msg_ok "Installed Node.js/Yarn"

msg_info "Installing Part-DB (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/Part-DB/Part-DB-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/Part-DB/Part-DB-server/archive/refs/tags/v${RELEASE}.zip"
unzip -q "v${RELEASE}.zip"
mv /opt/Part-DB-server-${RELEASE}/ /opt/partdb

cd /opt/partdb/
cp .env .env.local
sed -i "s|DATABASE_URL=\"sqlite:///%kernel.project_dir%/var/app.db\"|DATABASE_URL=\"postgresql://${DB_USER}:${DB_PASS}@127.0.0.1:5432/${DB_NAME}?serverVersion=12.19&charset=utf8\"|" .env.local

export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev -o --no-interaction
$STD yarn install
$STD yarn build
$STD php bin/console cache:clear
php bin/console doctrine:migrations:migrate -n > ~/database-migration-output
chown -R www-data:www-data /opt/partdb
ADMIN_PASS=$(grep -oP 'The initial password for the "admin" user is: \K\w+' ~/database-migration-output)
{
echo ""
echo "Part-DB Admin User: admin"
echo "Part-DB Admin Password: $ADMIN_PASS"
} >> ~/partdb.creds
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Part-DB"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/partdb.conf
<VirtualHost *:80>
    ServerName partdb
    DocumentRoot /opt/partdb/public
    <Directory /opt/partdb/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/partdb_error.log
    CustomLog /var/log/apache2/partdb_access.log combined
</VirtualHost>
EOF
$STD a2ensite partdb
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/database-migration-output
rm -rf "/opt/v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
