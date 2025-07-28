#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grocy.info/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_MODULE="sqlite3,bz2" PHP_APACHE="yes" setup_php
fetch_and_deploy_gh_release "grocy" "grocy/grocy" "prebuild" "latest" "/var/www/html" "grocy*.zip"

msg_info "Configuring grocy"
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
msg_ok "Cleaned"
