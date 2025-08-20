#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Forceu/barcodebuddy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  redis \
  sqlite3
msg_ok "Installed Dependencies"

PHP_VERSION="8.2" PHP_APACHE="YES" PHP_MODULE="redis, sqlite3" setup_php
fetch_and_deploy_gh_release "barcodebuddy" "Forceu/barcodebuddy"

msg_info "Configuring barcodebuddy"
chown -R www-data:www-data /opt/barcodebuddy/data
msg_ok "Configured barcodebuddy"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/barcodebuddy.service
[Unit]
Description=Run websocket server for barcodebuddy screen feature
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php /opt/barcodebuddy/wsserver.php
StandardOutput=null
Restart=on-failure
User=www-data

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/apache2/sites-available/barcodebuddy.conf
<VirtualHost *:80>
    ServerName barcodebuddy
    DocumentRoot /opt/barcodebuddy
    
    <Directory /opt/barcodebuddy>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/barcodebuddy_error.log
    CustomLog /var/log/apache2/barcodebuddy_access.log combined
</VirtualHost>
EOF
systemctl enable -q --now barcodebuddy
$STD a2ensite barcodebuddy
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
