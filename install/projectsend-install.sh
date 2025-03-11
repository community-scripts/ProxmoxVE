#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/

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
  mariadb-server \
  apache2 \
  libapache2-mod-php \
  php8.2-{pdo,mysql,mbstring,gettext,fileinfo,gd,xml,zip}
msg_ok "Installed Dependencies"

msg_info "Setting up MariaDB"
DB_NAME=projectsend
DB_USER=projectsend
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "projectsend-Credentials"
    echo "projectsend Database User: $DB_USER"
    echo "projectsend Database Password: $DB_PASS"
    echo "projectsend Database Name: $DB_NAME"
} >> ~/projectsend.creds
msg_ok "Set up MariaDB"

msg_info "Installing projectsend"
RELEASE=$(curl -s https://api.github.com/repos/projectsend/projectsend/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q "https://github.com/projectsend/projectsend/releases/download/r${RELEASE}/projectsend-r${RELEASE}.zip"
mkdir projectsend
unzip -q "projectsend-r${RELEASE}.zip" -d projectsend
mv /opt/projectsend/includes/sys.config.sample.php /opt/projectsend/includes/sys.config.php
chown -R www-data:www-data /opt/projectsend
chmod -R 775 /opt/projectsend
chmod 644 /opt/projectsend/includes/sys.config.php
sed -i -e "s/\(define('DB_NAME', \).*/\1'$DB_NAME');/" \
       -e "s/\(define('DB_USER', \).*/\1'$DB_USER');/" \
       -e "s/\(define('DB_PASSWORD', \).*/\1'$DB_PASS');/" \
       /opt/projectsend/includes/sys.config.php
sed -i -e "s/^\(memory_limit = \).*/\1 256M/" \
       -e "s/^\(post_max_size = \).*/\1 256M/" \
       -e "s/^\(upload_max_filesize = \).*/\1 256M/" \
       -e "s/^\(max_execution_time = \).*/\1 300/" \
       /etc/php/8.2/apache2/php.ini
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed projectsend"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/projectsend.conf
<VirtualHost *:80>
    ServerName projectsend
    DocumentRoot /opt/projectsend
    <Directory /opt/projectsend>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/projectsend_error.log
    CustomLog /var/log/apache2/projectsend_access.log combined
</VirtualHost>
EOF
$STD a2ensite projectsend
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/projectsend-r${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
