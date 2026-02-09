#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pelican-dev/panel

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" PHP_FPM="YES" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="panel" MARIADB_DB_USER="pelican" setup_mariadb_db
fetch_and_deploy_gh_release "pelican-panel" "pelican-dev/panel" "prebuild" "latest" "/opt/pelican-panel" "panel.tar.gz"

msg_info "Installing Pelican Panel"
cd /opt/pelican-panel
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan p:environment:setup
$STD php artisan p:environment:queue-service --no-interaction
echo "* * * * * php /opt/pelican-panel/artisan schedule:run >> /dev/null 2>&1" | crontab -u www-data -
chown -R www-data:www-data /opt/pelican-panel
chmod -R 755 /opt/pelican-panel/storage /opt/pelican-panel/bootstrap/cache/
msg_ok "Installed Pelican Panel"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/pelican.conf
<VirtualHost *:80>
    ServerName pelican
    DocumentRoot /opt/pelican-panel/public
    AllowEncodedSlashes On
    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory /opt/pelican-panel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/pelican_error.log
    CustomLog /var/log/apache2/pelican_access.log combined
</VirtualHost>
EOF
$STD a2ensite pelican
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
