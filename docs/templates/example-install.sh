#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: YOUR_NAME
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# Define application variables
APP_NAME="application"

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

# Install application-specific dependencies
msg_info "Installing ${APP_NAME} Dependencies"
$STD apt-get install -y \
    software-properties-common \
    apt-transport-https
msg_ok "Installed ${APP_NAME} Dependencies"

# Create application directories
msg_info "Creating Directories"
mkdir -p /opt/${APP_NAME}
mkdir -p /etc/${APP_NAME}
mkdir -p /var/lib/${APP_NAME}
msg_ok "Created Directories"

# Download and install application
msg_info "Installing ${APP_NAME}"
VERSION="1.0.0"
$STD wget -q "https://github.com/example/${APP_NAME}/releases/download/v${VERSION}/${APP_NAME}.tar.gz"
$STD tar -xzf "${APP_NAME}.tar.gz" -C /opt/${APP_NAME}
echo "${VERSION}" >"/opt/${APP_NAME}_version.txt"
msg_ok "Installed ${APP_NAME}"

# Configure application
msg_info "Configuring ${APP_NAME}"
# Generate random credentials
USERNAME="admin"
PASSWORD=$(head -c 50 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

# Write configuration file
cat <<EOF >/etc/${APP_NAME}/config.conf
PORT=${APP_PORT}
USERNAME=${USERNAME}
PASSWORD=${PASSWORD}
EOF

# Write environment file
cat <<EOF >/opt/${APP_NAME}/.env
APP_PORT=${APP_PORT}
APP_USER="${USERNAME}"
APP_PASS="${PASSWORD}"
EOF

# Store credentials
{
    echo "${APP_NAME} Credentials"
    echo "Username: ${USERNAME}"
    echo "Password: ${PASSWORD}"
} >> ~/${APP_NAME}.creds
msg_ok "Configured ${APP_NAME}"

# Create and configure service
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APP_NAME}.service
[Unit]
Description=${APP_NAME} Service
After=network.target

[Service]
Type=simple
User=${APP_NAME}
WorkingDirectory=/opt/${APP_NAME}
ExecStart=/opt/${APP_NAME}/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
$STD systemctl enable --now APP_NAME
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
