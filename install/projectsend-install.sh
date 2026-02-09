#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
setup_mariadb
MARIADB_DB_NAME="projectsend" MARIADB_DB_USER="projectsend" setup_mariadb_db
fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend" "projectsend-r*.zip"

msg_info "Installing ProjectSend"
mv /opt/projectsend/includes/sys.config.sample.php /opt/projectsend/includes/sys.config.php
chown -R www-data:www-data /opt/projectsend
chmod -R 775 /opt/projectsend
chmod 644 /opt/projectsend/includes/sys.config.php
sed -i -e "s/\(define('DB_NAME', \).*/\1'$MARIADB_DB_NAME');/" \
  -e "s/\(define('DB_USER', \).*/\1'$MARIADB_DB_USER');/" \
  -e "s/\(define('DB_PASSWORD', \).*/\1'$MARIADB_DB_PASS');/" \
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
cleanup_lxc
