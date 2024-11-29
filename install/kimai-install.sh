#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: MickLesk
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  apt-transport-https \
  sudo \
  mc \
  curl \
  apache2 \
  git \
  expect \
  composer \
  mariadb-server \
  libapache2-mod-php \
  php8.2-{mbstring,gd,intl,pdo,mysql,tokenizer,zip,xml} 
msg_ok "Installed Dependencies"

msg_info "Setting up database"
DB_NAME=kimai_db
DB_USER=kimai
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
MYSQL_VERSION=$(mysql --version | grep -oP 'Distrib \K[0-9]+\.[0-9]+\.[0-9]+')
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "Kimai-Credentials"
    echo "Kimai Database User: $DB_USER"
    echo "Kimai Database Password: $DB_PASS"
    echo "Kimai Database Name: $DB_NAME"
} >> ~/kimai.creds
msg_ok "Set up database"

msg_info "Installing Kimai (Patience)"
RELEASE=$(curl -s https://api.github.com/repos/kimai/kimai/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip"
unzip -q ${RELEASE}.zip
mv kimai-${RELEASE} /opt/kimai
cd /opt/kimai
echo "export COMPOSER_ALLOW_SUPERUSER=1" >> ~/.bashrc
source ~/.bashrc
$STD composer install --no-dev --optimize-autoloader --no-interaction
cp .env.dist .env
sed -i "/^DATABASE_URL=/c\DATABASE_URL=mysql://$DB_USER:$DB_PASS@127.0.0.1:3306/$DB_NAME?charset=utf8mb4&serverVersion=$MYSQL_VERSION" /opt/kimai/.env
$STD bin/console kimai:install -n
chown -R :www-data /opt/kimai
chmod -R g+r /opt/kimai
chmod -R g+rw /opt/kimai
sudo chown -R www-data:www-data /opt/kimai
sudo chmod -R 755 /opt/kimai
$STD expect <<EOF
set timeout -1
log_user 0

spawn bin/console kimai:user:create admin admin@helper-scripts.com ROLE_SUPER_ADMIN

expect "Please enter the password:"
send "helper-scripts.com\r"

expect eof
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Kimai"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/kimai.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/kimai/public/

   <Directory /opt/kimai/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
  
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
$STD a2ensite kimai.conf
$STD a2dissite 000-default.conf  
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
