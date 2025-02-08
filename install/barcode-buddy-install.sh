#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  apache2 \
  redis \
  php-{curl,date,json,mbstring,redis,sqlite3,sockets} \
  libapache2-mod-php
msg_ok "Installed Dependencies"

msg_info "Installing barcodebuddy"
RELEASE=$(curl -s https://api.github.com/repos/Forceu/barcodebuddy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q "https://github.com/Forceu/barcodebuddy/archive/refs/tags/v${RELEASE}.zip"
unzip -q "v${RELEASE}.zip"
mv "/opt/barcodebuddy-${RELEASE}" /opt/barcodebuddy
chown -R www-data:www-data /opt/barcodebuddy/data
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed barcodebuddy"

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
rm -rf "/opt/v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
