#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y apache2
$STD apt-get install -y php8.2
$STD apt-get install -y libapache2-mod-php
$STD apt-get install -y php8.2-curl
$STD apt-get install -y php8.2-zip
$STD apt-get install -y php8.2-mbstring
$STD apt-get install -y php8.2-xml
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Installing TasmoAdmin"
wget -q https://github.com/TasmoAdmin/TasmoAdmin/releases/download/v3.1.1/tasmoadmin_v3.1.1.tar.gz
tar -xzf tasmoadmin_v3.1.1.tar.gz -C /var/www/
rm -rf tasmoadmin_v3.1.1.tar.gz /etc/php/8.2/apache2/conf.d/10-opcache.ini
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
msg_ok "Installed TasmoAdmin"
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
