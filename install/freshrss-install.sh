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
  postgresql \
  apache2 \
  php-{curl,dom,json,ctype,pgsql,gmp,mbstring,iconv,zip} \
  libapache2-mod-php
msg_ok "Installed Dependencies"


msg_info "Setting up PostgreSQL"
DB_NAME=freshrss
DB_USER=freshrss
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
echo "FreshRSS Credentials"
echo "FreshRSS Database User: $DB_USER"
echo "FreshRSS Database Password: $DB_PASS"
echo "FreshRSS Database Name: $DB_NAME"
} >> ~/freshrss.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing FreshRSS"
RELEASE=$(curl -s https://api.github.com/repos/FreshRSS/FreshRSS/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
cd /opt
wget -q "https://github.com/FreshRSS/FreshRSS/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "/opt/FreshRSS-${RELEASE}" /opt/freshrss
cd /opt/freshrss
chown -R www-data:www-data /opt/freshrss
chmod -R g+rX /opt/freshrss
chmod -R g+w /opt/freshrss/data/
msg_ok "Installed FreshRSS"

msg_info "Setting up cron job for feed refresh"
cat <<EOF >/etc/cron.d/freshrss-actualize
*/15 * * * * www-data /bin/php -f /opt/freshrss/app/actualize_script.php > /tmp/FreshRSS.log 2>&1
EOF
chmod 644 /etc/cron.d/freshrss-actualize
msg_ok "Set up Cron - if you need to modify the timing edit file /etc/cron.d/freshrss-actualize"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/freshrss.conf
<VirtualHost *:80>
    ServerName freshrss
    DocumentRoot /opt/freshrss/p

    <Directory /opt/freshrss/p>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/freshrss_error.log
    CustomLog /var/log/apache2/freshrss_access.log combined

    AllowEncodedSlashes On
</VirtualHost>
EOF
$STD a2ensite freshrss
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
