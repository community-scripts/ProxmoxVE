#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL e.g. https://github.com/example/app]

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES - Only add app-specific dependencies here!
# Don't add: ca-certificates, curl, gnupg, git, build-essential (handled by build.func)
# =============================================================================

msg_info "Installing Dependencies"
$STD apt install -y \
  libharfbuzz0b \
  fontconfig
msg_ok "Installed Dependencies"

# =============================================================================
# SETUP RUNTIMES & DATABASES (if needed)
# =============================================================================
# Examples (uncomment as needed):
#
#   NODE_VERSION="22" setup_nodejs
#   NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs  # Installs pnpm
#   PYTHON_VERSION="3.13" setup_uv
#   JAVA_VERSION="21" setup_java
#   GO_VERSION="1.22" setup_go
#   PHP_VERSION="8.4" PHP_FPM="YES" setup_php
#   setup_postgresql           # Server only
#   setup_mariadb              # Server only
#   setup_meilisearch          # Search engine
#
#   Then set up DB and user (sets $[DB]_DB_PASS):
#   PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
#   MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp" setup_mariadb_db

# =============================================================================
# DOWNLOAD & DEPLOY APPLICATION
# =============================================================================
# fetch_and_deploy_gh_release modes:
#   "tarball"  - Source tarball (default if omitted)
#   "binary"   - .deb package (auto-detects amd64/arm64)
#   "prebuild" - Pre-built archive (.tar.gz)
#   "singlefile" - Single binary file
#
# Examples:
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "tarball" "latest" "/opt/myapp"
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "binary" "latest" "/tmp"
#   fetch_and_deploy_gh_release "myapp" "YourUsername/myapp" "prebuild" "latest" "/opt/myapp" "myapp-*.tar.gz"

fetch_and_deploy_gh_release "[appname]" "owner/repo" "tarball" "latest" "/opt/[appname]"

# --- Tools & Utilities ---
# get_lxc_ip                          # Sets $LOCAL_IP variable (call early!)
# setup_ffmpeg                             # Install FFmpeg with codecs
# setup_hwaccel                            # Setup GPU hardware acceleration
# setup_imagemagick                        # Install ImageMagick 7
# setup_docker                             # Install Docker Engine
# setup_adminer                            # Install Adminer for DB management
# create_self_signed_cert                  # Creates cert in /etc/ssl/[appname]/

# =============================================================================
# EXAMPLES
# =============================================================================
#
# EXAMPLE 1: Node.js Application with PostgreSQL
# ---------------------------------------------
# NODE_VERSION="22" setup_nodejs
# PG_VERSION="17" setup_postgresql
# PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
# get_lxc_ip
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
#
# EXAMPLE 2: Python Application with uv
# ------------------------------------
# PYTHON_VERSION="3.13" setup_uv
# get_lxc_ip
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
# get_lxc_ip
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
# 2. Call get_lxc_ip if you need the container IP
# 3. Use fetch_and_deploy_gh_release to download the app (handles version tracking)
# 4. Configure the application
# 5. Create systemd service
# 6. Finalize with motd_ssh, customize, cleanup_lxc

# --- Setup runtimes/databases ---
NODE_VERSION="22" setup_nodejs
get_lxc_ip

# --- Download and install app ---
fetch_and_deploy_gh_release "[appname]" "[owner/repo]" "tarball" "latest" "/opt/[appname]"

msg_info "Setting up [AppName]"
cd /opt/[appname]
# $STD npm ci
msg_ok "Setup [AppName]"

# =============================================================================
# CONFIGURATION
# =============================================================================

msg_info "Configuring [AppName]"
cd /opt/[appname]

# Install application dependencies (uncomment as needed):
# $STD npm ci --production         # Node.js apps
# $STD uv sync --frozen            # Python apps
# $STD composer install --no-dev   # PHP apps
# $STD cargo build --release       # Rust apps

# Create .env file if needed:
cat <<EOF >/opt/[appname]/.env
# Use import_local_ip to get container IP, or hardcode if building on Proxmox
APP_URL=http://localhost
PORT=8080
EOF

msg_ok "Configured [AppName]"

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
# These are called automatically, but shown here for clarity:
#   motd_ssh           - Displays service info on SSH login
#   customize          - Enables optional customizations
#   cleanup_lxc        - Removes temp files, bash history, logs

motd_ssh
customize
cleanup_lxc
