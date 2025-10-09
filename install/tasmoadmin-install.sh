#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TasmoAdmin/TasmoAdmin

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

PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
fetch_and_deploy_gh_release "tasmoadmin" "TasmoAdmin/TasmoAdmin" "prebuild" "latest" "/var/www/tasmoadmin" "tasmoadmin_v*.tar.gz"

msg_info "Configuring TasmoAdmin"
rm -rf /etc/php/8.4/apache2/conf.d/10-opcache.ini
chown -R www-data:www-data /var/www/tasmoadmin
chmod 777 /var/www/tasmoadmin/tmp /var/www/tasmoadmin/data
cat <<EOF >/etc/apache2/sites-available/tasmoadmin.conf
<VirtualHost *:9999>
	ServerName tasmoadmin
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/tasmoadmin
	<Directory /var/www/tasmoadmin>
	AllowOverride All
	Order allow,deny
	allow from all
	</Directory>
	ErrorLog /var/log/apache2/error.log
	LogLevel warn
	CustomLog /var/log/apache2/access.log combined
	ServerSignature On
</VirtualHost>
EOF
sed -i '6iListen 9999' /etc/apache2/ports.conf
$STD a2ensite tasmoadmin
$STD a2enmod rewrite
systemctl reload apache2
systemctl restart apache2
msg_ok "Configured TasmoAdmin"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
