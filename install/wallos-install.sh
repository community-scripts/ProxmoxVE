#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ellite/wallos

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
  libapache2-mod-php \
  php8.2-{mbstring,gd,curl,intl,imagick,bz2,sqlite3,zip,xml} 
msg_ok "Installed Dependencies"

msg_info "Installing Wallos (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/ellite/Wallos/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/ellite/Wallos/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv Wallos-${RELEASE} /opt/wallos
cd /opt/wallos
mv /opt/wallos/db/wallos.empty.db /opt/wallos/db/wallos.db
chown -R www-data:www-data /opt/wallos
chmod -R 755 /opt/wallos
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"

cat <<EOF >/etc/apache2/sites-available/wallos.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /opt/wallos

    <Directory /opt/wallos>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/wallos_error.log
    CustomLog \${APACHE_LOG_DIR}/wallos_access.log combined
</VirtualHost>
EOF
$STD a2ensite wallos.conf
$STD a2dissite 000-default.conf  
$STD systemctl reload apache2
$STD curl http://localhost/endpoints/db/migrate.php
msg_ok "Installed Wallos"

msg_info "Setting up Crontabs" 
mkdir -p /var/log/cron
cat <<EOF > /opt/wallos.cron
0 1 * * * php /opt/wallos/endpoints/cronjobs/updatenextpayment.php >> /var/log/cron/updatenextpayment.log 2>&1
0 2 * * * php /opt/wallos/endpoints/cronjobs/updateexchange.php >> /var/log/cron/updateexchange.log 2>&1
0 8 * * * php /opt/wallos/endpoints/cronjobs/sendcancellationnotifications.php >> /var/log/cron/sendcancellationnotifications.log 2>&1
0 9 * * * php /opt/wallos/endpoints/cronjobs/sendnotifications.php >> /var/log/cron/sendnotifications.log 2>&1
*/2 * * * * php /opt/wallos/endpoints/cronjobs/sendverificationemails.php >> /var/log/cron/sendverificationemail.log 2>&1
*/2 * * * * php /opt/wallos/endpoints/cronjobs/sendresetpasswordemails.php >> /var/log/cron/sendresetpasswordemails.log 2>&1
0 */6 * * * php /opt/wallos/endpoints/cronjobs/checkforupdates.php >> /var/log/cron/checkforupdates.log 2>&1
EOF
crontab /opt/wallos.cron
msg_ok "Crontabs setup"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
