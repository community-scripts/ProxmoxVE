#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Omar Minaya | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkstack.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.3" PHP_MODULE="sqlite3" PHP_APACHE="YES" setup_php
fetch_and_deploy_gh_release "linkstack" "linkstackorg/linkstack" "prebuild" "latest" "/var/www/html/" "linkstack.zip"

msg_info "Configuring LinkStack"
$STD a2enmod rewrite
chown -R www-data:www-data /var/www/html/linkstack
chmod -R 755 /var/www/html/linkstack

cat <<EOF >/etc/apache2/sites-available/linkstack.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/linkstack
    ErrorLog /var/log/apache2/linkstack-error.log
    CustomLog /var/log/apache2/linkstack-access.log combined
    <Directory /var/www/html/linkstack/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
$STD a2dissite 000-default.conf
$STD a2ensite linkstack.conf
$STD systemctl restart apache2
msg_ok "Configured LinkStack"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
