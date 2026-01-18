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
#   PYTHON_VERSION="3.13" setup_uv
#   JAVA_VERSION="17" setup_java
#   GO_VERSION="1.22" setup_go
#   PHP_VERSION="8.4" PHP_FPM="YES" setup_php
#   setup_postgresql           # Server only
#   setup_mariadb              # Server only
#
#   Then set up DB and user:
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

fetch_and_deploy_gh_release "[appname]" "YourUsername/YourRepo" "tarball" "latest" "/opt/[appname]"

# =============================================================================
# CONFIGURE APPLICATION
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
