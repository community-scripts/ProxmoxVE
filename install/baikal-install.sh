#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  postgresql \
  apache2 \
  libapache2-mod-php \
  php-{pgsql,dom}
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=baikal
DB_USER=baikal
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
echo "Baikal Credentials"
echo "Baikal Database User: $DB_USER"
echo "Baikal Database Password: $DB_PASS"
echo "Baikal Database Name: $DB_NAME"
} >> ~/baikal.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Baikal"
RELEASE=$(curl -s https://api.github.com/repos/sabre-io/Baikal/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
cd /opt
wget -q "https://github.com/sabre-io/baikal/releases/download/${RELEASE}/baikal-${RELEASE}.zip"
unzip -q "baikal-${RELEASE}.zip"
cat <<EOF >/opt/baikal/config/baikal.yaml
database:
    backend: pgsql
    pgsql_host: localhost
    pgsql_dbname: $DB_NAME
    pgsql_username: $DB_USER
    pgsql_password: $DB_PASS
EOF
chown -R www-data:www-data /opt/baikal/
chmod -R 755 /opt/baikal/
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Baikal"

msg_info "Creating Service"
cat <<EOF > /etc/apache2/sites-available/baikal.conf
<VirtualHost *:80>
    ServerName baikal
    DocumentRoot /opt/baikal/html

    RewriteEngine on
    RewriteRule /.well-known/carddav /dav.php [R=308,L]
    RewriteRule /.well-known/caldav  /dav.php [R=308,L]
    RewriteCond %{REQUEST_URI} ^/dav.php$ [NC]
    RewriteRule ^(.*)$ /dav.php/ [R=301,L]
        
    <Directory /opt/baikal/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <IfModule mod_expires.c>
        ExpiresActive Off
    </IfModule>

    ErrorLog /var/log/apache2/baikal_error.log
    CustomLog /var/log/apache2/baikal_access.log combined
</VirtualHost>
EOF
$STD a2ensite baikal
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/baikal-${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
