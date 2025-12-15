#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: mrosero
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tt-rss.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.2" PHP_MODULE="curl,xml,mbstring,intl,zip,pgsql,gmp" PHP_APACHE="YES" setup_php
PG_VERSION="16" setup_postgresql
PG_DB_NAME="ttrss" PG_DB_USER="ttrss" setup_postgresql_db
import_local_ip || {
  msg_error "Failed to determine LOCAL_IP"
  exit 1
}
if [[ -z "${LOCAL_IP:-}" ]]; then
  msg_error "LOCAL_IP is not set"
  exit 1
fi

msg_info "Downloading TinyTinyRSS"
mkdir -p /opt/tt-rss
curl -fsSL https://github.com/tt-rss/tt-rss/archive/refs/heads/main.tar.gz -o /tmp/tt-rss.tar.gz
$STD tar -xzf /tmp/tt-rss.tar.gz -C /tmp
$STD cp -r /tmp/tt-rss-main/* /opt/tt-rss/
rm -rf /tmp/tt-rss.tar.gz /tmp/tt-rss-main
echo "main" >"/opt/TinyTinyRSS_version.txt"
msg_ok "Downloaded TinyTinyRSS"

msg_info "Configuring TinyTinyRSS"
cd /opt/tt-rss || exit
mkdir -p /opt/tt-rss/feed-icons /opt/tt-rss/lock /opt/tt-rss/cache
chown -R www-data:www-data /opt/tt-rss
chmod -R g+rX /opt/tt-rss
chmod -R g+w /opt/tt-rss/feed-icons /opt/tt-rss/lock /opt/tt-rss/cache
msg_ok "Configured TinyTinyRSS"

msg_info "Setting up cron job for feed refresh"
cat <<EOF >/etc/cron.d/tt-rss-update-feeds
*/15 * * * * www-data /bin/php -f /opt/tt-rss/update.php -- --feeds --quiet > /tmp/tt-rss.log 2>&1
EOF
chmod 644 /etc/cron.d/tt-rss-update-feeds
msg_ok "Set up Cron - if you need to modify the timing edit file /etc/cron.d/tt-rss-update-feeds"

msg_info "Creating Apache Configuration"
cat <<EOF >/etc/apache2/sites-available/tt-rss.conf
<VirtualHost *:80>
    ServerName tt-rss
    DocumentRoot /opt/tt-rss

    <Directory /opt/tt-rss>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/tt-rss_error.log
    CustomLog /var/log/apache2/tt-rss_access.log combined

    AllowEncodedSlashes On
</VirtualHost>
EOF
$STD a2ensite tt-rss
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Apache Configuration"

msg_info "Creating initial config.php"
if [ ! -f /opt/tt-rss/config.php ]; then
  cat <<EOF >/opt/tt-rss/config.php
<?php
define('DB_TYPE', 'pgsql');
define('DB_HOST', 'localhost');
define('DB_NAME', '$PG_DB_NAME');
define('DB_USER', '$PG_DB_USER');
define('DB_PASS', '$PG_DB_PASS');
define('DB_PORT', '5432');

define('SELF_URL_PATH', 'http://${LOCAL_IP}/');

define('FEED_CRYPT_KEY', '$(openssl rand -hex 32)');

define('SINGLE_USER_MODE', false);
define('SIMPLE_UPDATE_MODE', false);
EOF
  chown www-data:www-data /opt/tt-rss/config.php
  chmod 644 /opt/tt-rss/config.php
  msg_ok "Created initial config.php"
else
  msg_info "config.php already exists, skipping creation"
fi

motd_ssh
customize
cleanup_lxc

