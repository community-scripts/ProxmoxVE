#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PHP_VERSION="8.4" PHP_FPM="YES" PHP_APACHE="YES" PHP_MODULE="snmp,imap" setup_php
setup_mariadb
MARIADB_DB_NAME="wordpress_db" MARIADB_DB_USER="wordpress" setup_mariadb_db
fetch_and_deploy_from_url "https://wordpress.org/latest.zip" /var/www/html/wordpress

msg_info "Installing Wordpress (Patience)"
chown -R www-data:www-data /var/www/html/wordpress
cd /var/www/html/wordpress
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
mv wp-config-sample.php wp-config.php
sed -i -e "s|^define( 'DB_NAME', '.*' );|define( 'DB_NAME', '$MARIADB_DB_NAME' );|" \
  -e "s|^define( 'DB_USER', '.*' );|define( 'DB_USER', '$MARIADB_DB_USER' );|" \
  -e "s|^define( 'DB_PASSWORD', '.*' );|define( 'DB_PASSWORD', '$MARIADB_DB_PASS' );|" \
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
cleanup_lxc
