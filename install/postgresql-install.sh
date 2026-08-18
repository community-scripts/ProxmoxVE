#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.postgresql.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  read -r -p "${TAB3}Enter PostgreSQL version (15/16/17/18): " ver
  [[ $ver =~ ^(15|16|17|18)$ ]] || {
    echo "Invalid version"
    exit 64
  }
  PG_VERSION=$ver setup_postgresql

  cat <<EOF >/etc/postgresql/$ver/main/pg_hba.conf
# PostgreSQL Client Authentication Configuration File
local   all             postgres                                peer
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             0.0.0.0/24              md5
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
host    all             all             0.0.0.0/0               md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

  cat <<EOF >/etc/postgresql/$ver/main/postgresql.conf
# -----------------------------
# PostgreSQL configuration file
# -----------------------------

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = '/var/lib/postgresql/$ver/main'       
hba_file = '/etc/postgresql/$ver/main/pg_hba.conf'     
ident_file = '/etc/postgresql/$ver/main/pg_ident.conf'   
external_pid_file = '/var/run/postgresql/$ver-main.pid'                   

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = '*'                 
port = 5432                             
max_connections = 100                  
unix_socket_directories = '/var/run/postgresql' 

# - SSL -

ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

shared_buffers = 128MB                
dynamic_shared_memory_type = posix      

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

max_wal_size = 1GB
min_wal_size = 80MB

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - What to Log -

log_line_prefix = '%m [%p] %q%u@%d '           
log_timezone = 'Etc/UTC'

#------------------------------------------------------------------------------
# PROCESS TITLE
#------------------------------------------------------------------------------

cluster_name = '$ver/main'                

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Locale and Formatting -

datestyle = 'iso, mdy'
timezone = 'Etc/UTC'
lc_messages = 'C'                      
lc_monetary = 'C'                       
lc_numeric = 'C'                        
lc_time = 'C'                           
default_text_search_config = 'pg_catalog.english'

#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------

include_dir = 'conf.d'                  
EOF

  systemctl restart postgresql
  msg_ok "Installed PostgreSQL"

  read -r -p "${TAB3}Would you like to add Adminer? <y/N> " prompt
  if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "Installing Adminer"
    $STD apt install -y adminer
    $STD a2enconf adminer
    systemctl reload apache2
    msg_ok "Installed Adminer"
  fi
}

setup_alpine() {
  read -r -p "${TAB3}Enter PostgreSQL version (15/16/17): " ver
  [[ $ver =~ ^(15|16|17)$ ]] || { echo "Invalid version"; exit 64; }

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
    sed -i 's|/usr/bin/php-cgi|/usr/bin/php-cgi83|g' /etc/lighttpd/mod_fastcgi.conf
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
}

run_os_setup

motd_ssh
customize
cleanup_lxc
