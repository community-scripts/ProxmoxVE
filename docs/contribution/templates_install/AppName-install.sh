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
# AVAILABLE HELPER FUNCTIONS (from tools.func)
# =============================================================================
#
# LANGUAGE/RUNTIME SETUP (use these, DON'T do manual installation!):
#   NODE_VERSION="22" setup_nodejs             # Node.js (18, 20, 22)
#   PYTHON_VERSION="3.13" setup_uv             # Python with uv package manager
#   GO_VERSION="1.22" setup_go                 # Go language
#   RUST_CRATES="monolith" setup_rust          # Rust
#   RUBY_VERSION="3.3" setup_ruby              # Ruby
#   JAVA_VERSION="21" setup_java               # Java (17, 21)
#   PHP_VERSION="8.4" setup_php                # PHP
#
# DATABASE SETUP (use these instead of manual setup!):
#   setup_postgresql                           # PostgreSQL server
#   PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db   # Create DB & user
#   setup_mariadb                              # MariaDB server
#   MARIADB_DB_NAME="mydb" setup_mariadb_db    # Create MariaDB DB
#   setup_mysql                                # MySQL server
#   setup_mongodb                              # MongoDB server
#
# GITHUB RELEASES (PREFERRED - handles versioning automatically!):
#   fetch_and_deploy_gh_release "appname" "owner/repo"          # Auto-detect mode
#   fetch_and_deploy_gh_release "appname" "owner/repo" "binary" # .deb package
#   CLEAN_INSTALL=1 fetch_and_deploy_gh_release ...             # Clean install (remove old dir first)
#
# UTILITIES:
#   import_local_ip                    # Sets $LOCAL_IP variable (call early!)
#   setup_ffmpeg                       # FFmpeg with codecs
#   setup_imagemagick                  # ImageMagick 7
#   setup_hwaccel                      # GPU acceleration
#   setup_docker                       # Docker Engine
#   setup_adminer                      # Adminer (DB web interface)

# =============================================================================
# DEPENDENCIES
# =============================================================================

msg_info "Installing Dependencies"
$STD apt install -y \
  ca-certificates \
  curl \
  gnupg
msg_ok "Installed Dependencies"

# =============================================================================
# EXAMPLE: Node.js App with PostgreSQL
# =============================================================================
# NODE_VERSION="22" setup_nodejs
# PG_VERSION="17" setup_postgresql
# PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
# import_local_ip
#
# msg_info "Deploying Application"
# fetch_and_deploy_gh_release "myapp" "owner/myapp"
# msg_ok "Deployed Application"
#
# msg_info "Installing Dependencies"
# cd /opt/myapp
# $STD npm ci --production
# msg_ok "Installed Dependencies"
#
# msg_info "Configuring Environment"
# cat <<EOF >/opt/myapp/.env
# DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
# APP_HOST=${LOCAL_IP}
# APP_PORT=3000
# NODE_ENV=production
# EOF
# msg_ok "Configured Environment"

# =============================================================================
# EXAMPLE: Python App with uv
# =============================================================================
# PYTHON_VERSION="3.13" setup_uv
# import_local_ip
# msg_info "Deploying Application"
# fetch_and_deploy_gh_release "myapp" "owner/myapp"
# msg_ok "Deployed Application"
#
# msg_info "Installing Dependencies"
# cd /opt/myapp
# $STD uv sync --frozen
# msg_ok "Installed Dependencies"
#
# cat <<EOF >/opt/myapp/.env
# HOST=${LOCAL_IP}
# PORT=8000
# DEBUG=false
# EOF

# =============================================================================
# CREATE SYSTEMD SERVICE
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
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/[appname]/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now [appname]
msg_ok "Created Service"
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
