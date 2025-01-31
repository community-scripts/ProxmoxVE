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
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Installing PHP8.2"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
echo -e "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $VERSION main" >/etc/apt/sources.list.d/php.list
$STD apt-get update
$STD apt-get install -y php8.2
$STD apt-get install -y libapache2-mod-php8.2
$STD apt-get install -y php8.2-sqlite3
$STD apt-get install -y php8.2-gd
$STD apt-get install -y php8.2-intl
$STD apt-get install -y php8.2-mbstring
msg_ok "Installed PHP8.2"

msg_info "Installing grocy"
latest=$(curl -s https://api.github.com/repos/grocy/grocy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/grocy/grocy/releases/download/v${latest}/grocy_${latest}.zip
$STD unzip grocy_${latest}.zip -d /var/www/html
chown -R www-data:www-data /var/www/html
cp /var/www/html/config-dist.php /var/www/html/data/config.php
chmod +x /var/www/html/update.sh

cat <<EOF >/etc/apache2/sites-available/grocy.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /var/www/html/public
  ErrorLog /var/log/apache2/error.log
<Directory /var/www/html/public>
  Options Indexes FollowSymLinks MultiViews
  AllowOverride All
  Order allow,deny
  allow from all
</Directory>
</VirtualHost>
EOF

$STD a2dissite 000-default.conf
$STD a2ensite grocy.conf
$STD a2enmod rewrite
systemctl reload apache2
msg_ok "Installed grocy"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf /root/grocy_${latest}.zip
msg_ok "Cleaned"
