#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL e.g. https://github.com/example/app]

# Import Functions and Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES
# =============================================================================
# Only install what's actually needed - curl/sudo/mc are already in the base image

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  build-essential
msg_ok "Installed Dependencies"

# =============================================================================
# HELPER FUNCTIONS FROM tools.func
# =============================================================================
# These functions are available via $FUNCTIONS_FILE_PATH (tools.func)
# Call them with optional environment variables for configuration
#
# --- Runtime & Language Setup ---
# NODE_VERSION="22" setup_nodejs           # Install Node.js (22, 24)
# NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs  # With pnpm
# PYTHON_VERSION="3.13" setup_uv           # Python with uv package manager
# setup_go                                 # Install Go (latest)
# setup_rust                               # Install Rust via rustup
# setup_ruby                               # Install Ruby
# PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="mysqli,gd" setup_php
# PHP_VERSION="8.3" PHP_FPM="YES" PHP_APACHE="YES" PHP_MODULE="bcmath,curl,gd,intl,mbstring,mysql,xml,zip" setup_php
# setup_composer                           # Install PHP Composer
# JAVA_VERSION="21" setup_java             # Install Java (17, 21)
#
# --- Database Setup ---
# setup_mariadb                            # Install MariaDB server
# MARIADB_DB_NAME="mydb" MARIADB_DB_USER="myuser" setup_mariadb_db
# setup_mysql                              # Install MySQL server
# PG_VERSION="17" setup_postgresql         # Install PostgreSQL (16, 17)
# PG_VERSION="17" PG_MODULES="postgis" setup_postgresql  # With extensions
# PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db
# setup_mongodb                            # Install MongoDB
#
# --- GitHub Release (PREFERRED METHOD) ---
# fetch_and_deploy_gh_release "appname" "owner/repo" "tarball"  # Downloads, extracts, tracks version
# fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
# fetch_and_deploy_gh_release "appname" "owner/repo" "prebuild" "latest" "/opt/appname" "app-*.tar.gz"
#
# --- Tools & Utilities ---
# import_local_ip                          # Sets $LOCAL_IP variable (call early!)
# setup_ffmpeg                             # Install FFmpeg with codecs
# setup_hwaccel                            # Setup GPU hardware acceleration
# setup_imagemagick                        # Install ImageMagick 7
# setup_docker                             # Install Docker Engine
# setup_adminer                            # Install Adminer for DB management
# create_self_signed_cert                  # Creates cert in /etc/ssl/[appname]/

# =============================================================================
# EXAMPLE 1: Node.js Application with PostgreSQL
# =============================================================================
# NODE_VERSION="22" setup_nodejs
# PG_VERSION="17" setup_postgresql
# PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
# import_local_ip
# fetch_and_deploy_gh_release "myapp" "owner/myapp" "tarball" "latest" "/opt/myapp"
#
# msg_info "Configuring MyApp"
# cd /opt/myapp
# $STD npm ci
# cat <<EOF >/opt/myapp/.env
# DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
# HOST=${LOCAL_IP}
# PORT=3000
# EOF
# msg_ok "Configured MyApp"

# =============================================================================
# EXAMPLE 2: Python Application with uv
# =============================================================================
# PYTHON_VERSION="3.13" setup_uv
# import_local_ip
# fetch_and_deploy_gh_release "myapp" "owner/myapp" "tarball" "latest" "/opt/myapp"
#
# msg_info "Setting up MyApp"
# cd /opt/myapp
# $STD uv sync
# cat <<EOF >/opt/myapp/.env
# HOST=${LOCAL_IP}
# PORT=8000
# EOF
# msg_ok "Setup MyApp"

# =============================================================================
# EXAMPLE 3: PHP Application with MariaDB + Nginx
# =============================================================================
# PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="bcmath,curl,gd,intl,mbstring,mysql,xml,zip" setup_php
# setup_composer
# setup_mariadb
# MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp" setup_mariadb_db
# import_local_ip
# fetch_and_deploy_gh_release "myapp" "owner/myapp" "prebuild" "latest" "/opt/myapp" "myapp-*.tar.gz"
#
# msg_info "Configuring MyApp"
# cd /opt/myapp
# cp .env.example .env
# sed -i "s|APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
# sed -i "s|DB_DATABASE=.*|DB_DATABASE=${MARIADB_DB_NAME}|" .env
# sed -i "s|DB_USERNAME=.*|DB_USERNAME=${MARIADB_DB_USER}|" .env
# sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${MARIADB_DB_PASS}|" .env
# $STD composer install --no-dev --no-interaction
# chown -R www-data:www-data /opt/myapp
# msg_ok "Configured MyApp"

# =============================================================================
# YOUR APPLICATION INSTALLATION
# =============================================================================
# 1. Setup runtimes and databases FIRST
# 2. Call import_local_ip if you need the container IP
# 3. Use fetch_and_deploy_gh_release to download the app (handles version tracking)
# 4. Configure the application
# 5. Create systemd service
# 6. Finalize with motd_ssh, customize, cleanup_lxc

# --- Setup runtimes/databases ---
NODE_VERSION="22" setup_nodejs
import_local_ip

# --- Download and install app ---
fetch_and_deploy_gh_release "[appname]" "[owner/repo]" "tarball" "latest" "/opt/[appname]"

msg_info "Setting up [AppName]"
cd /opt/[appname]
$STD npm ci
msg_ok "Setup [AppName]"

# =============================================================================
# CONFIGURATION
# =============================================================================

msg_info "Configuring [AppName]"
cat <<EOF >/opt/[appname]/.env
HOST=${LOCAL_IP}
PORT=8080
EOF
msg_ok "Configured [AppName]"

# =============================================================================
# SERVICE CREATION
# =============================================================================

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/[appname].service
[Unit]
Description=[AppName] Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/[appname]
ExecStart=/usr/bin/node /opt/[appname]/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now [appname]
msg_ok "Created Service"

# =============================================================================
# CLEANUP & FINALIZATION
# =============================================================================

motd_ssh
customize

# cleanup_lxc handles: apt autoremove, autoclean, temp files, bash history
cleanup_lxc
