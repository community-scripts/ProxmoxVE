#!/usr/bin/env bash

# Copyright (c) 2021-2025 communtiy-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wordpress.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="common,snmp,imap,mysql" PHP_APACHE="YES" setup_php
setup_mariadb

msg_info "Setting up Database"
DB_NAME=wordpress_db
DB_USER=wordpress
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "WordPress Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/wordpress.creds
msg_ok "Set up Database"

msg_info "Installing Wordpress (Patience)"
cd /var/www/html
curl -fsSL "https://wordpress.org/latest.zip" -o "latest.zip"
$STD unzip latest.zip
chown -R www-data:www-data wordpress/
cd /var/www/html/wordpress
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
mv wp-config-sample.php wp-config.php
sed -i -e "s|^define( 'DB_NAME', '.*' );|define( 'DB_NAME', '$DB_NAME' );|" \
  -e "s|^define( 'DB_USER', '.*' );|define( 'DB_USER', '$DB_USER' );|" \
  -e "s|^define( 'DB_PASSWORD', '.*' );|define( 'DB_PASSWORD', '$DB_PASS' );|" \
  /var/www/html/wordpress/wp-config.php
msg_ok "Installed Wordpress"

msg_info "Setup Services"
cat <<EOF >/etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerName yourdomain.com
    DocumentRoot /var/www/html/wordpress

    <Directory /var/www/html/wordpress>
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF
$STD a2ensite wordpress.conf
$STD a2dissite 000-default.conf
systemctl reload apache2
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /var/www/html/latest.zip
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
