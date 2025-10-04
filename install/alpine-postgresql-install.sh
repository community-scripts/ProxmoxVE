#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.postgresql.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -r -p "${TAB3}Enter PostgreSQL version (15/16/17): " ver
[[ $ver =~ ^(15|16|17)$ ]] || { echo "Invalid version"; exit 1; }

msg_info "Installing PostgreSQL ${ver}"
$STD apk add --no-cache postgresql${ver} postgresql${ver}-contrib postgresql${ver}-openrc sudo
msg_ok "Installed PostgreSQL ${ver}"

msg_info "Enabling PostgreSQL Service"
$STD rc-update add postgresql default
msg_ok "Enabled PostgreSQL Service"

msg_info "Starting PostgreSQL"
$STD rc-service postgresql start
msg_ok "Started PostgreSQL"

msg_info "Configuring PostgreSQL for External Access"
conf_file="/etc/postgresql${ver}/postgresql.conf"
hba_file="/etc/postgresql${ver}/pg_hba.conf"
sed -i 's/^#listen_addresses =.*/listen_addresses = '\''*'\''/' "$conf_file"
sed -i '/^host\s\+all\s\+all\s\+127.0.0.1\/32\s\+md5/ s/.*/host all all 0.0.0.0\/0 md5/' "$hba_file"
$STD rc-service postgresql restart
msg_ok "Configured and Restarted PostgreSQL"

read -r -p "${TAB3}Would you like to install Adminer with lighttpd? <y/N>: " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Adminer and dependencies"
  $STD apk add --no-cache \
    lighttpd \
    lighttpd-openrc \
    php83 \
    php83-cgi \
    php83-common \
    php83-curl \
    php83-gd \
    php83-mbstring \
    php83-pdo \
    php83-pgsql \
    php83-openssl \
    php83-zip \
    php83-session \
    jq

  sed -i 's|# *include "mod_fastcgi.conf"|include "mod_fastcgi.conf"|' /etc/lighttpd/lighttpd.conf
  mkdir -p /var/www/localhost/htdocs
  ADMINER_VERSION=$(curl -fsSL https://api.github.com/repos/vrana/adminer/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php" -o /var/www/localhost/htdocs/adminer.php
  chown lighttpd:lighttpd /var/www/localhost/htdocs/adminer.php
  chmod 755 /var/www/localhost/htdocs/adminer.php
  msg_ok "Adminer Installed"

  msg_info "Starting Lighttpd"
  $STD rc-update add lighttpd default
  $STD rc-service lighttpd restart
  msg_ok "Lighttpd Started"
fi

motd_ssh
customize
