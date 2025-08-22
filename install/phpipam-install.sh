#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://phpipam.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y php-pear
msg_ok "Installed Dependencies"

PHP_VERSION="8.2" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="mysql,imap,apcu,pspell,tidy,xmlrpc,gmp,ldap,common,snmp" setup_php
setup_mariadb

msg_info "Setting up MariaDB"
DB_NAME=phpipam
DB_USER=phpipam
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "phpIPAM-Credentials"
  echo "phpIPAM Database User: $DB_USER"
  echo "phpIPAM Database Password: $DB_PASS"
  echo "phpIPAM Database Name: $DB_NAME"
} >>~/phpipam.creds
msg_ok "Set up MariaDB"

fetch_and_deploy_gh_release "phpipam" "phpipam/phpipam" "prebuild" "latest" "/opt/phpipam" "phpipam-v*.zip"

msg_info "Installing phpIPAM"
$STD mariadb -u root "${DB_NAME}" </opt/phpipam/db/SCHEMA.sql
cp /opt/phpipam/config.dist.php /opt/phpipam/config.php
sed -i -e "s/\(\$disable_installer = \).*/\1true;/" \
  -e "s/\(\$db\['user'\] = \).*/\1'$DB_USER';/" \
  -e "s/\(\$db\['pass'\] = \).*/\1'$DB_PASS';/" \
  -e "s/\(\$db\['name'\] = \).*/\1'$DB_NAME';/" \
  /opt/phpipam/config.php
sed -i '/max_execution_time/s/= .*/= 600/' /etc/php/8.2/apache2/php.ini
msg_ok "Installed phpIPAM"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/phpipam.conf
<VirtualHost *:80>
    ServerName phpipam
    DocumentRoot /opt/phpipam
    <Directory /opt/phpipam>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/phpipam_error.log
    CustomLog /var/log/apache2/phpipam_access.log combined
</VirtualHost>
EOF
$STD a2ensite phpipam
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
