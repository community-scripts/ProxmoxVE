#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="pdo,mysql,gettext,fileinfo" setup_php
setup_mariadb
fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend" "projectsend-r*.zip"

msg_info "Setting up MariaDB"
DB_NAME=projectsend
DB_USER=projectsend
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "projectsend-Credentials"
  echo "projectsend Database User: $DB_USER"
  echo "projectsend Database Password: $DB_PASS"
  echo "projectsend Database Name: $DB_NAME"
} >>~/projectsend.creds
msg_ok "Set up MariaDB"

msg_info "Installing ProjectSend"
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
  /etc/php/8.4/apache2/php.ini
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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
