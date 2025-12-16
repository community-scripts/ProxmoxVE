#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: mrosero
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tt-rss.org/

APPLICATION="TinyTinyRSS"

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.2" PHP_MODULE="curl,xml,mbstring,intl,zip,pgsql,gmp" PHP_APACHE="YES" setup_php
PG_VERSION="16" setup_postgresql

msg_info "Setting up PostgreSQL"
DB_NAME=ttrss
DB_USER=ttrss
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
  echo "TinyTinyRSS Credentials"
  echo "TinyTinyRSS Database User: $DB_USER"
  echo "TinyTinyRSS Database Password: $DB_PASS"
  echo "TinyTinyRSS Database Name: $DB_NAME"
} >>~/tinytinyrss.creds

# Configure pg_hba.conf to use md5 for local connections (instead of peer)
# This ensures password authentication works even when using Unix sockets
PG_HBA_CONF=$(find /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1)
if [[ -n "$PG_HBA_CONF" ]]; then
  # Backup pg_hba.conf
  cp "$PG_HBA_CONF" "${PG_HBA_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
  
  # Change local connections from peer/ident to md5
  sed -i '/^local\s\+all\s\+all\s\+peer/s/peer$/md5/' "$PG_HBA_CONF"
  sed -i '/^local\s\+all\s\+all\s\+ident/s/ident$/md5/' "$PG_HBA_CONF"
  
  # Ensure TCP/IP connections use md5
  if ! grep -qE "^host\s+all\s+all\s+127\.0\.0\.1/32\s+(md5|scram-sha-256)" "$PG_HBA_CONF" 2>/dev/null; then
    sed -i '/^# IPv4 local connections:/a host    all             all             127.0.0.1/32            md5' "$PG_HBA_CONF"
  fi
  
  # Reload PostgreSQL to apply changes
  systemctl reload postgresql || systemctl restart postgresql
fi

msg_ok "Set up PostgreSQL"

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
# Remove any existing config.php or config-dist.php to avoid conflicts
rm -f /opt/tt-rss/config.php /opt/tt-rss/config-dist.php
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
# Ensure variables are set before creating config.php
if [[ -z "${DB_NAME:-}" || -z "${DB_USER:-}" || -z "${DB_PASS:-}" ]]; then
  msg_error "Database variables not set. DB_NAME, DB_USER, and DB_PASS must be available."
  exit 1
fi

# Generate feed crypt key
FEED_CRYPT_KEY=$(openssl rand -hex 32)

# Create config.php using printf to ensure proper variable expansion
{
  printf "<?php\n"
  printf "define('DB_TYPE', 'pgsql');\n"
  printf "define('DB_HOST', '127.0.0.1');\n"
  printf "define('DB_NAME', '%s');\n" "$DB_NAME"
  printf "define('DB_USER', '%s');\n" "$DB_USER"
  printf "define('DB_PASS', '%s');\n" "$DB_PASS"
  printf "define('DB_PORT', '5432');\n"
  printf "\n"
  printf "define('SELF_URL_PATH', 'http://%s/');\n" "$LOCAL_IP"
  printf "\n"
  printf "define('FEED_CRYPT_KEY', '%s');\n" "$FEED_CRYPT_KEY"
  printf "\n"
  printf "define('SINGLE_USER_MODE', false);\n"
  printf "define('SIMPLE_UPDATE_MODE', false);\n"
} >/opt/tt-rss/config.php

# Verify config.php was created with correct values
if ! grep -q "define('DB_USER', '${DB_USER}');" /opt/tt-rss/config.php; then
  msg_error "Failed to create config.php with correct database credentials"
  exit 1
fi

# Double-check the file contents
if ! grep -q "define('DB_NAME', 'ttrss');" /opt/tt-rss/config.php; then
  msg_error "config.php does not contain expected database name"
  exit 1
fi

chown www-data:www-data /opt/tt-rss/config.php
chmod 644 /opt/tt-rss/config.php
msg_ok "Created initial config.php"

motd_ssh
customize
cleanup_lxc

