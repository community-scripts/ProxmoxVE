#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: Don Locke (DonLocke)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wavelog/wavelog

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
  libapache2-mod-php \
  mariadb-server \
  mc \
  php8.2-{curl,mbstring,mysql,xml,zip,gd} \
  sudo \
  unzip
msg_ok "Installed Dependencies"

msg_info "Setting up Database"
DB_NAME=wavelog
DB_USER=waveloguser
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "Wavelog-Credentials"
    echo "Wavelog Database User: $DB_USER"
    echo "Wavelog Database Password: $DB_PASS"
    echo "Wavelog Database Name: $DB_NAME"
} >> ~/wavelog.creds
msg_ok "Set up database"

msg_info "Setting up PHP"
sed -i '/max_execution_time/s/= .*/= 600/' /etc/php/8.2/apache2/php.ini
sed -i '/memory_limit/s/= .*/= 256M/' /etc/php/8.2/apache2/php.ini
sed -i '/upload_max_filesize/s/= .*/= 8M/' /etc/php/8.2/apache2/php.ini
msg_ok "Set up PHP"

msg_info "Installing Wavelog"
RELEASE=$(curl -s https://api.github.com/repos/wavelog/wavelog/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/wavelog/wavelog/archive/refs/tags/${RELEASE}.zip"
unzip -q ${RELEASE}.zip
mv wavelog-${RELEASE}/ /opt/wavelog
chown -R www-data:www-data /opt/wavelog/
find /opt/wavelog/ -type d -exec chmod 755 {} \;
find /opt/wavelog/ -type f -exec chmod 664 {} \;
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Wavelog"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/wavelog.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /opt/wavelog

    <Directory /opt/wavelog>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF
$STD a2ensite wavelog.conf
$STD a2dissite 000-default.conf  
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f ${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
