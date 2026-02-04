#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://zitadel.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Configuration variables
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ZITADEL_BINARY_ARCHIVE="${SCRIPT_DIR}/zitadel-linux-amd64.tar.gz"
# ZITADEL_LOGIN_ARCHIVE="${SCRIPT_DIR}/zitadel-login.tar.gz"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/opt/zitadel"
LOGIN_DIR="/opt/login"
CREDS_FILE="${HOME}/zitadel.creds"
RERUN_SCRIPT="${HOME}/zitadel-rerun.sh"

msg_info "Installing Dependencies (Patience)"
$STD apt install -y ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    openssl \
    lsof
msg_ok "Installed Dependecies"

fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "latest" "${INSTALL_DIR}" "zitadel-linux-amd64.tar.gz"
# Might need to chmod +x "$INSTALL_DIR/zitadel"

fetch_and_deploy_gh_release "login" "zitadel/zitadel" "prebuild" "latest" "${LOGIN_DIR}" "zitadel-login.tar.gz"
# # The archive extracts to apps/login/ structure
# if [[ -d "$LOGIN_DIR/apps/login" ]]; then
    # mv "$LOGIN_DIR/apps/login"/* "$LOGIN_DIR/" 2>/dev/null || true
    # rm -rf "$LOGIN_DIR/apps"
# fi

#NODE_VERSION="24" NODE_MODULE="pnpm@latest" setup_nodejs
NODE_VERSION="24" setup_nodejs
#node apps/login/server.js

PG_VERSION="17" setup_postgresql

msg_info "Installing Postgresql"
DB_NAME="zitadel"
DB_USER="zitadel"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
DB_ADMIN_USER="postgres"
DB_ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
systemctl start postgresql
# $STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
# $STD sudo -u postgres psql -c "CREATE USER $DB_ADMIN_USER WITH PASSWORD '$DB_ADMIN_PASS' SUPERUSER;"
# $STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_ADMIN_USER;"

# Set postgres user password - ZITADEL will create the database and zitadel user automatically
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_ADMIN_PASS';"

{
    echo "==================================="
    echo "ZITADEL DATABASE CREDENTIALS"
    echo "==================================="
    echo "DB_NAME: $DB_NAME"
    echo "DB_USER: $DB_USER"
    echo "DB_PASS: $DB_PASS"
    echo "DB_ADMIN_USER: $DB_ADMIN_USER"
    echo "DB_ADMIN_PASS: $DB_ADMIN_PASS"
    echo "==================================="
    echo ""
    echo "NOTE: ZITADEL will automatically create"
    echo "the database and user on first run."
    echo "==================================="
} | tee "$CREDS_FILE"
msg_ok "Installed PostgreSQL"

msg_info "Setting up Zitadel Environments"
mkdir -p "$CONFIG_DIR"
echo "$CONFIG_DIR/config.yaml" > "$CONFIG_DIR/.config"
head -c 32 < <(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9') > "$CONFIG_DIR/.masterkey"
{
    echo "==================================="
    echo "Config location: $(cat "$CONFIG_DIR/.config")"
    echo "Masterkey: $(cat "$CONFIG_DIR/.masterkey")"
    echo "==================================="
} | tee -a "$CREDS_FILE"


# Get IP address
IP=$(ip a s dev eth0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
if [[ -z "$IP" ]]; then
    # Fallback to other interfaces
    IP=$(hostname -I | awk '{print $1}')
fi
if [[ -z "$IP" ]]; then
    IP="localhost"
    msg_warn "Could not detect IP address, using localhost"
fi

cat <<EOF >/opt/zitadel/config.yaml
Port: 8080
ExternalPort: 8080
ExternalDomain: ${IP}
ExternalSecure: false
TLS:
  Enabled: false
  KeyPath: ""
  Key: ""
  CertPath: ""
  Cert: ""

Database:
  postgres:
    Host: localhost
    Port: 5432
    Database: ${DB_NAME}
    User:
      Username: ${DB_USER}
      Password: ${DB_PASS}
      SSL:
        Mode: disable
        RootCert: ""
        Cert: ""
        Key: ""
    Admin:
      Username: ${DB_ADMIN_USER}
      Password: ${DB_ADMIN_PASS}
      SSL:
        Mode: disable
        RootCert: ""
        Cert: ""
        Key: ""
FirstInstance:
  LoginClientPatPath: ${CONFIG_DIR}/login-client.pat
  PatPath: ${CONFIG_DIR}/admin.pat
  InstanceName: ZITADEL
  DefaultLanguage: en
  Org:
    Human:
      Username: zitadel-admin@zitadel.localhost
      Password: Password1!
DefaultInstance:
  Features:
    LoginV2:
      Required: true
      BaseURI: http://${IP}:3000/ui/v2/login

AssetStorage:
  Type: db

Login:
  Path: ${LOGIN_DIR}
EOF
msg_ok "Installed Zitadel Enviroments"

# Create zitadel user
msg_info "Creating zitadel system user"
if ! id -u zitadel >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin zitadel
    msg_ok "User 'zitadel' created"
else
    msg_warn "User 'zitadel' already exists"
fi

# Set permissions
chown -R zitadel:zitadel "$CONFIG_DIR"
chmod 600 "$CONFIG_DIR/.masterkey"
chmod 644 "$CONFIG_DIR/config.yaml"
msg_ok "Created zitadel system user"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/zitadel.service
[Unit]
Description=ZITADEL Identiy Server
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=zitadel
Group=zitadel
# Environment="ZITADEL_DATABASE_POSTGRES_HOST=localhost"
# Environment="ZITADEL_DATABASE_POSTGRES_PORT=5432"
# Environment="ZITADEL_DATABASE_POSTGRES_DATABASE=${DB_NAME}"
# Environment="ZITADEL_DATABASE_POSTGRES_USER_USERNAME=${DB_USER}"
# Environment="ZITADEL_DATABASE_POSTGRES_USER_PASSWORD=${DB_PASS}"
# Environment="ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable"
# Environment="ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME=${DB_ADMIN_USER}"
# Environment="ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD=${DB_ADMIN_PASS}"
# Environment="ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable"
ExecStart=/usr/local/bin/zitadel start -m $CONFIG_DIR/.masterkey --config $CONFIG_DIR/config.yaml
Restart=always
RestartSec=5
TimeoutStartSec=0

# Security Hardening options
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
#systemctl enable -q --now zitadel
msg_ok "Created Services"

msg_info "Zitadel initial setup"
export ZITADEL_DATABASE_POSTGRES_HOST=localhost
export ZITADEL_DATABASE_POSTGRES_PORT=5432
export ZITADEL_DATABASE_POSTGRES_DATABASE="$DB_NAME"
export ZITADEL_DATABASE_POSTGRES_USER_USERNAME="$DB_USER"
export ZITADEL_DATABASE_POSTGRES_USER_PASSWORD="$DB_PASS"
export ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable
export ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME="$DB_ADMIN_USER"
export ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD="$DB_ADMIN_PASS"
export ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable

# Run init phase - ZITADEL will create database, user, and schemas
$STD zitadel init --config "$CONFIG_DIR/config.yaml"
$STD zitadel setup -m "$CONFIG_DIR/.masterkey" --config "$CONFIG_DIR/config.yaml" --steps "$CONFIG_DIR/config.yaml"
systemctl enable -q --now zitadel
sleep 5
msg_ok "Zitadel initialized"

msg_info "Creating configuration rerun script"
cat <<EOF > "$RERUN_SCRIPT"
#!/bin/bash
# Rerun Zitadel setup after configuration changes

set -e

CONFIG_DIR="/opt/zitadel"

echo "Stopping Zitadel service..."
systemctl stop zitadel

echo "Running Zitadel setup..."
export ZITADEL_DATABASE_POSTGRES_HOST=localhost
export ZITADEL_DATABASE_POSTGRES_PORT=5432
export ZITADEL_DATABASE_POSTGRES_DATABASE=${DB_NAME}
export ZITADEL_DATABASE_POSTGRES_USER_USERNAME=${DB_USER}
export ZITADEL_DATABASE_POSTGRES_USER_PASSWORD=${DB_PASS}
export ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable
export ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME=${DB_ADMIN_USER}
export ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD=${DB_ADMIN_PASS}
export ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable

zitadel setup -m "\$CONFIG_DIR/.masterkey" --config "\$CONFIG_DIR/config.yaml" --steps "\$CONFIG_DIR/config.yaml"
sleep 5

echo "Starting Zitadel service..."
systemctl start zitadel

echo "Zitadel restarted successfully!"
EOF
chmod +x "$RERUN_SCRIPT"
msg_ok "Rerun script created at $RERUN_SCRIPT"

motd_ssh
customize
cleanup_lxc
