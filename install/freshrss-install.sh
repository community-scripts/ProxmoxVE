#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FreshRSS/FreshRSS

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
PG_VERSION="16" setup_postgresql
PG_DB_NAME="freshrss" PG_DB_USER="freshrss_usr" setup_postgresql_db

fetch_and_deploy_gh_release "freshrss" "FreshRSS/FreshRSS" "tarball"

msg_info "Configuring FreshRSS"
cd /opt/freshrss
chown -R www-data:www-data /opt/freshrss
chmod -R g+rX /opt/freshrss
chmod -R g+w /opt/freshrss/data/
msg_ok "Configured FreshRSS"

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
$STD a2enmod rewrite deflate expires headers mime setenvif
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
