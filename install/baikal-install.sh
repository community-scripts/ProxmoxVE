#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sabre.io/baikal/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PHP_APACHE="YES" PHP_VERSION="8.3" setup_php
setup_composer
fetch_and_deploy_gh_release "baikal" "sabre-io/Baikal" "tarball"
PG_DB_NAME="baikal_db" PG_DB_USER="baikal_user" PG_DB_PASS="$(openssl rand -base64 12)" setup_postgresql_db

msg_info "Configuring Baikal"
cd /opt/baikal
$STD composer install
cat <<EOF >/opt/baikal/config/baikal.yaml
database:
    backend: pgsql
    pgsql_host: localhost
    pgsql_dbname: $PG_DB_NAME
    pgsql_username: $PG_DB_USER
    pgsql_password: $PG_DB_PASS
EOF
chown -R www-data:www-data /opt/baikal/
chmod -R 755 /opt/baikal/
msg_ok "Installed Baikal"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/baikal.conf
<VirtualHost *:80>
    ServerName baikal
    DocumentRoot /opt/baikal/html

    RewriteEngine on
    RewriteRule /.well-known/carddav /dav.php [R=308,L]
    RewriteRule /.well-known/caldav  /dav.php [R=308,L]
    RewriteCond %{REQUEST_URI} ^/dav.php$ [NC]
    RewriteRule ^(.*)$ /dav.php/ [R=301,L]
        
    <Directory /opt/baikal/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <IfModule mod_expires.c>
        ExpiresActive Off
    </IfModule>

    ErrorLog /var/log/apache2/baikal_error.log
    CustomLog /var/log/apache2/baikal_access.log combined
</VirtualHost>
EOF
$STD a2ensite baikal
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
