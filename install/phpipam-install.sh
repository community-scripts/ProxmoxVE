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

PHP_VERSION="8.3" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="mysql,gmp,snmp,ldap,apcu" setup_php

msg_info "Installing PHP-PEAR"
$STD apt install -y \
  php-pear \
  php-dev
msg_ok "Installed PHP-PEAR"

setup_mariadb
MARIADB_DB_NAME="phpipam" MARIADB_DB_USER="phpipam" setup_mariadb_db
fetch_and_deploy_gh_release "phpipam" "phpipam/phpipam" "prebuild" "latest" "/opt/phpipam" "phpipam-v*.zip"

msg_info "Installing phpIPAM"
$STD mariadb -u root "${MARIADB_DB_NAME}" </opt/phpipam/db/SCHEMA.sql
cp /opt/phpipam/config.dist.php /opt/phpipam/config.php
sed -i -e "s/\(\$disable_installer = \).*/\1true;/" \
  -e "s/\(\$db\['user'\] = \).*/\1'$MARIADB_DB_USER';/" \
  -e "s/\(\$db\['pass'\] = \).*/\1'$MARIADB_DB_PASS';/" \
  -e "s/\(\$db\['name'\] = \).*/\1'$MARIADB_DB_NAME';/" \
  /opt/phpipam/config.php
sed -i '/max_execution_time/s/= .*/= 600/' /etc/php/8.3/apache2/php.ini
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
cleanup_lxc
