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

# Configure PostgreSQL to force TCP/IP connections and use md5 authentication
# This prevents PDO from using Unix sockets which don't send passwords correctly
PG_HBA_CONF=$(find /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1)
PG_CONF=$(find /etc/postgresql/*/main/postgresql.conf 2>/dev/null | head -1)

if [[ -n "$PG_HBA_CONF" ]]; then
  # Backup pg_hba.conf
  cp "$PG_HBA_CONF" "${PG_HBA_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
  
  # Change all local peer/ident lines to md5 (for Unix sockets if they're used)
  sed -i '/^local\s\+all\s\+all\s\+peer/s/peer$/md5/' "$PG_HBA_CONF"
  sed -i '/^local\s\+all\s\+all\s\+ident/s/ident$/md5/' "$PG_HBA_CONF"
  
  # Ensure there's a local md5 line (before any peer lines)
  if ! grep -qE "^local\s+all\s+all\s+md5" "$PG_HBA_CONF" 2>/dev/null; then
    if grep -q "^# \"local\" is for Unix domain socket connections only" "$PG_HBA_CONF"; then
      sed -i '/^# "local" is for Unix domain socket connections only/a local   all             all                                     md5' "$PG_HBA_CONF"
    elif grep -q "^local\s\+all\s\+postgres" "$PG_HBA_CONF"; then
      sed -i '/^local\s\+all\s\+postgres/i local   all             all                                     md5' "$PG_HBA_CONF"
    fi
  fi
  
  # Change TCP/IP connections from scram-sha-256 to md5 for compatibility
  # This ensures password authentication works correctly
  sed -i '/^host\s\+all\s\+all\s\+127\.0\.0\.1\/32/s/scram-sha-256/md5/' "$PG_HBA_CONF"
  sed -i '/^host\s\+all\s\+all\s\+::1\/128/s/scram-sha-256/md5/' "$PG_HBA_CONF"
  
  # Ensure TCP/IP connections use md5 if they don't exist
  if ! grep -qE "^\s*host\s+all\s+all\s+127\.0\.0\.1/32\s+md5" "$PG_HBA_CONF" 2>/dev/null; then
    sed -i '/^# IPv4 local connections:/a host    all             all             127.0.0.1/32            md5' "$PG_HBA_CONF"
  fi
fi

# Disable Unix sockets in PostgreSQL to force TCP/IP connections
# This ensures PDO always uses TCP/IP and sends passwords correctly
# Note: unix_socket_directories requires a full restart, not just reload
if [[ -n "$PG_CONF" ]]; then
  # Backup postgresql.conf
  cp "$PG_CONF" "${PG_CONF}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
  
  # Comment out unix_socket_directories to disable Unix sockets
  # Match lines that may have leading spaces
  if grep -qE "^\s*unix_socket_directories" "$PG_CONF" 2>/dev/null; then
    sed -i 's/^\s*unix_socket_directories/#unix_socket_directories/' "$PG_CONF"
  fi
  # Add commented line if it doesn't exist
  if ! grep -qE "^\s*#unix_socket_directories" "$PG_CONF" 2>/dev/null; then
    echo "# Unix sockets disabled to force TCP/IP connections" >> "$PG_CONF"
    echo "#unix_socket_directories = '/var/run/postgresql'" >> "$PG_CONF"
  fi
fi

# Restart PostgreSQL to apply changes (restart required for unix_socket_directories)
if [[ -n "$PG_HBA_CONF" ]] || [[ -n "$PG_CONF" ]]; then
  msg_info "Restarting PostgreSQL to apply configuration changes"
  systemctl restart postgresql
  msg_ok "PostgreSQL restarted"
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

# Create config.php using putenv() with TTRSS_* variables (official method per documentation)
# Use 127.0.0.1 to force TCP/IP connection (localhost might use Unix socket)
{
  printf "<?php\n"
  printf "putenv('TTRSS_DB_TYPE=pgsql');\n"
  printf "putenv('TTRSS_DB_HOST=127.0.0.1');\n"
  printf "putenv('TTRSS_DB_NAME=%s');\n" "$DB_NAME"
  printf "putenv('TTRSS_DB_USER=%s');\n" "$DB_USER"
  printf "putenv('TTRSS_DB_PASS=%s');\n" "$DB_PASS"
  printf "putenv('TTRSS_DB_PORT=5432');\n"
  printf "putenv('TTRSS_SELF_URL_PATH=http://%s/');\n" "$LOCAL_IP"
  printf "\n"
  printf "// Legacy plugin-required constants\n"
  printf "define('FEED_CRYPT_KEY', '%s');\n" "$FEED_CRYPT_KEY"
} >/opt/tt-rss/config.php

# Verify config.php was created with correct values
if ! grep -q "putenv('TTRSS_DB_USER=${DB_USER}');" /opt/tt-rss/config.php; then
  msg_error "Failed to create config.php with correct database credentials"
  exit 1
fi

# Double-check the file contents
if ! grep -q "putenv('TTRSS_DB_NAME=${DB_NAME}');" /opt/tt-rss/config.php; then
  msg_error "config.php does not contain expected database name"
  exit 1
fi

chown www-data:www-data /opt/tt-rss/config.php
chmod 644 /opt/tt-rss/config.php
msg_ok "Created initial config.php"

# Initialize database schema
msg_info "Initializing database schema"
cd /opt/tt-rss
# Use --update-schema=force-yes to avoid interactive prompt
$STD sudo -u www-data /usr/bin/php update.php --update-schema=force-yes
msg_ok "Database schema initialized"

# Create or update admin user with secure password
msg_info "Configuring admin user"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
# Check if admin user exists, if not create it, if yes update password
if sudo -u www-data /usr/bin/php update.php --user-exists="$ADMIN_USER" >/dev/null 2>&1; then
  # User exists, update password
  $STD sudo -u www-data /usr/bin/php update.php --user-set-password="$ADMIN_USER:$ADMIN_PASS"
else
  # User doesn't exist, create it with admin access level (10)
  $STD sudo -u www-data /usr/bin/php update.php --user-add="$ADMIN_USER:$ADMIN_PASS:10"
fi
{
  echo ""
  echo "TinyTinyRSS Admin Credentials"
  echo "Admin Username: $ADMIN_USER"
  echo "Admin Password: $ADMIN_PASS"
  echo ""
  echo "TinyTinyRSS Database Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/tinytinyrss.creds
msg_ok "Admin user configured"

# Restart Apache to ensure it picks up the new config.php
msg_info "Restarting Apache to apply configuration"
systemctl restart apache2
msg_ok "Apache restarted"

motd_ssh
customize
cleanup_lxc

