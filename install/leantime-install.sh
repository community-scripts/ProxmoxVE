#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Stroopwafe1
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://leantime.io

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_MODULE="mysql" PHP_APACHE="YES" PHP_FPM="YES" setup_php
setup_mariadb

msg_info "Setting up Database"
DB_NAME=leantime
DB_USER=leantime
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Leantime Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/leantime.creds
msg_ok "Set up Database"

fetch_and_deploy_gh_release "leantime" "Leantime/leantime" "prebuild" "latest" "/opt/leantime" Leantime*.tar.gz

msg_info "Setup Leantime"
chown -R www-data:www-data "/opt/leantime"
chmod -R 750 "/opt/leantime"
cat <<EOF >/etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/leantime/public
  DirectoryIndex index.php index.html index.cgi index.pl index.xhtml
  Options +ExecCGI

  <Directory /opt/leantime/>
    Options FollowSymLinks
    Require all granted
    AllowOverride All
  </Directory>

  <Location />
    Require all granted
  </Location>

  ErrorLog /var/log/apache2/error.log
  CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF
mv "/opt/leantime/config/sample.env" "/opt/leantime/config/.env"
sed -i -e "s|^LEAN_DB_DATABASE.*|LEAN_DB_DATABASE = '$DB_NAME'|" \
  -e "s|^LEAN_DB_USER.*|LEAN_DB_USER = '$DB_USER'|" \
  -e "s|^LEAN_DB_PASSWORD.*|LEAN_DB_PASSWORD = '$DB_PASS'|" \
  -e "s|^LEAN_SESSION_PASSWORD.*|LEAN_SESSION_PASSWORD = '$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)'|" \
  "/opt/leantime/config/.env"
$STD a2enmod -q proxy_fcgi setenvif rewrite
$STD a2enconf -q "php8.4-fpm"
sed -i -e "s/^;extension.\(curl\|fileinfo\|gd\|intl\|ldap\|mbstring\|exif\|mysqli\|odbc\|openssl\|pdo_mysql\)/extension=\1/g" "/etc/php/8.4/apache2/php.ini"
systemctl restart apache2
msg_ok "Setup leantime"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
