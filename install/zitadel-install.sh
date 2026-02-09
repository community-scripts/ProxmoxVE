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
ZITADEL_DIR="/opt/zitadel"
LOGIN_DIR="/opt/login"
CONFIG_DIR="/etc/zitadel"
ZITADEL_USER="zitadel"
ZITADEL_GROUP="zitadel"
DB_NAME="zitadel"
DB_USER="zitadel"
DB_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
POSTGRES_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
MASTERKEY="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
API_PORT="8080"
LOGIN_PORT="3000"

# Detect server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Create zitadel user
msg_info "Creating zitadel system user"
groupadd --system "${ZITADEL_GROUP}"
useradd --system --gid "${ZITADEL_GROUP}" --shell /bin/bash --home-dir "${ZITADEL_DIR}" "${ZITADEL_USER}"
msg_ok "Created zitadel system user"

fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "latest" "${ZITADEL_DIR}" "zitadel-linux-amd64.tar.gz"
chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}"

fetch_and_deploy_gh_release "login" "zitadel/zitadel" "prebuild" "latest" "${LOGIN_DIR}" "zitadel-login.tar.gz"
chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${LOGIN_DIR}"

NODE_VERSION="24" setup_nodejs

PG_VERSION="17" setup_postgresql

setup_go

msg_info "Configuring Postgresql"
$STD sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_ADMIN_PASSWORD}';"
msg_ok "Configured PostgreSQL"

msg_info "Installing Zitadel"
cd "${ZITADEL_DIR}"
mkdir -p ${CONFIG_DIR}
echo -n "${MASTERKEY}" > ${CONFIG_DIR}/.masterkey
chmod 600 "${CONFIG_DIR}/.masterkey"
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${CONFIG_DIR}/.masterkey"

# Update config.yaml for network access
cat > "${CONFIG_DIR}/config.yaml" <<EOF
ExternalSecure: false
ExternalDomain: ${SERVER_IP}
ExternalPort: ${API_PORT}

TLS:
  Enabled: false

Log:
  Level: info
  Formatter:
    Format: text

Database:
  Postgres:
    Database: ${DB_NAME}
    Host: localhost
    Port: 5432
    AwaitInitialConn: 5m
    MaxOpenConns: 20
    MaxIdleConns: 20
    ConnMaxLifetime: 60m
    ConnMaxIdleTime: 10m
    User:
      Username: ${DB_USER}
      Password: ${DB_PASSWORD}
      SSL:
        Mode: disable
    Admin:
      Username: postgres
      Password: ${POSTGRES_ADMIN_PASSWORD}
      SSL:
        Mode: disable

FirstInstance:
  LoginClientPatPath: login-client.pat
  PatPath: admin.pat
  InstanceName: ZITADEL
  DefaultLanguage: en
  Org:
    LoginClient:
      Machine:
        Username: login-client
        Name: Automatically Initialized IAM Login Client
      Pat:
        ExpirationDate: 2099-01-01T00:00:00Z
    Machine:
      Machine:
        Username: admin
        Name: Automatically Initialized IAM admin Client
      Pat:
        ExpirationDate: 2099-01-01T00:00:00Z
    Human:
      Username: zitadel-admin@zitadel.localhost
      Password: Password1!
      PasswordChangeRequired: false

DefaultInstance:
  Features:
    LoginV2:
      BaseURI: http://${SERVER_IP}:${LOGIN_PORT}/ui/v2/login
EOF
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${CONFIG_DIR}/config.yaml"

# Initialize database as zitadel user (no masterkey needed for init)
$STD sudo -u ${ZITADEL_USER} ./zitadel init --config ${CONFIG_DIR}/config.yaml

# Run setup phase as zitadel user (with masterkey and steps)
$STD sudo -u ${ZITADEL_USER} ./zitadel setup --config ${CONFIG_DIR}/config.yaml --steps ${CONFIG_DIR}/config.yaml --masterkey "${MASTERKEY}"

#Read client token
CLIENT_PAT=$(cat ${ZITADEL_DIR}/login-client.pat)

# Update Login V2 login.env file
cat > "${CONFIG_DIR}/login.env" <<EOF
NEXT_PUBLIC_BASE_PATH=/ui/v2/login
EMAIL_VERIFICATION=false
ZITADEL_API_URL=http://${SERVER_IP}:${API_PORT}
ZITADEL_SERVICE_USER_TOKEN_FILE=../../login-client.pat
ZITADEL_SERVICE_USER_TOKEN=${CLIENT_PAT}
EOF
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${CONFIG_DIR}/login.env"

# Create api.env file
cat > "${CONFIG_DIR}/api.env" <<EOF
ZITADEL_MASTERKEY=${MASTERKEY}
ZITADEL_DATABASE_POSTGRES_HOST=localhost
ZITADEL_DATABASE_POSTGRES_PORT=5432
ZITADEL_DATABASE_POSTGRES_DATABASE=${DB_NAME}
ZITADEL_DATABASE_POSTGRES_USER_USERNAME=${DB_USER}
ZITADEL_DATABASE_POSTGRES_USER_PASSWORD=${DB_PASSWORD}
ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable
ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME=postgres
ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD}
ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable
ZITADEL_EXTERNALSECURE=false
EOF

# Set secure permissions
chmod 600 "${CONFIG_DIR}/api.env"
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${CONFIG_DIR}/api.env"
msg_ok "Installed Zitadel"

msg_info "Creating Services"
# Create API service
cat > /etc/systemd/system/zitadel-api.service <<EOF
[Unit]
Description=ZITADEL API Server
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=${ZITADEL_USER}
Group=${ZITADEL_GROUP}
WorkingDirectory=${ZITADEL_DIR}
EnvironmentFile=${CONFIG_DIR}/api.env
Environment="PATH=/usr/local/bin:/usr/local/go/bin:/usr/bin:/bin"
ExecStart=${ZITADEL_DIR}/zitadel start --config ${CONFIG_DIR}/config.yaml --masterkeyFile ${CONFIG_DIR}/.masterkey
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create Login V2 service
cat > /etc/systemd/system/zitadel-login.service <<EOF
[Unit]
Description=ZITADEL Login V2 Service
After=network.target zitadel-api.service
Requires=zitadel-api.service

[Service]
Type=simple
User=${ZITADEL_USER}
Group=${ZITADEL_GROUP}
WorkingDirectory=${LOGIN_DIR}/apps/login
EnvironmentFile=${CONFIG_DIR}/login.env
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="NODE_ENV=production"
ExecStart=node ${LOGIN_DIR}/apps/login/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start API service
systemctl enable -q --now zitadel-api.service

# Wait for API to start
sleep 5

# Enable and start Login service
systemctl enable -q --now zitadel-login.service
msg_ok "Created Services"

msg_info "Saving Credentials"
# Create credentials file
cat > "${CONFIG_DIR}/INSTALLATION_INFO.txt" <<EOF
################################################################################
# ZITADEL Installation Information
# Generated: $(date)
################################################################################

SERVER INFORMATION:
-------------------
Server IP: ${SERVER_IP}
API Port: ${API_PORT}
Login Port: ${LOGIN_PORT}

ACCESS URLS:
------------
Management Console: http://${SERVER_IP}:${API_PORT}/ui/console
Login V2 UI: http://${SERVER_IP}:${LOGIN_PORT}/ui/v2/login
API Endpoint: http://${SERVER_IP}:${API_PORT}

DEFAULT ADMIN CREDENTIALS:
--------------------------
Username: zitadel-admin@zitadel.localhost
Password: Password1!

IMPORTANT: Change this password immediately after first login!

DATABASE CREDENTIALS:
---------------------
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASSWORD}
PostgreSQL Admin Password: ${POSTGRES_ADMIN_PASSWORD}

SECURITY:
---------
Master Key: ${MASTERKEY}

IMPORTANT: Keep these credentials secure and backup this file!

VERIFICATION:
-------------
1. Check API health:
   curl http://${SERVER_IP}:${API_PORT}/debug/healthz
2. Access Management Console:
   http://${SERVER_IP}:${API_PORT}/ui/console
3. Login with admin credentials above

DATABASE INFORMATION:
--------------------
The database and user are automatically created by ZITADEL on first startup.
ZITADEL uses the admin credentials to create:
  - Database: ${DB_NAME}
  - User: ${DB_USER}
  - Schemas: eventstore, projections, system

PRODUCTION NOTES:
-----------------
1. This installation uses HTTP (not HTTPS) for simplicity
2. For production with HTTPS:
   - Set ExternalSecure: true in config.yaml
   - Configure TLS certificates
   - Update firewall rules for port 443
3. Change all default passwords immediately
4. Set up regular database backups
5. Configure proper monitoring and alerting
6. Review and harden PostgreSQL security settings

BACKUP COMMANDS:
----------------
Database backup:
  PGPASSWORD=${DB_PASSWORD} pg_dump -h localhost -U ${DB_USER} ${DB_NAME} > zitadel_backup_\$(date +%Y%m%d).sql

Database restore:
  PGPASSWORD=${DB_PASSWORD} psql -h localhost -U ${DB_USER} ${DB_NAME} < zitadel_backup_YYYYMMDD.sql

################################################################################
EOF
chmod 600 "${CONFIG_DIR}/INSTALLATION_INFO.txt"
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${CONFIG_DIR}/INSTALLATION_INFO.txt"
cp ${ZITADEL_DIR}/admin.pat ${CONFIG_DIR}/admin.pat.BAK
cp ${ZITADEL_DIR}/login-client.pat ${CONFIG_DIR}/login-client.pat.BAK
msg_ok "Saved Credentials"

msg_info "Create zitadel-rerun.sh"
cat <<EOF >~/zitadel-rerun.sh
systemctl stop zitadel-api zitadel-login
timeout --kill-after=5s 15s /opt/zitadel/zitadel setup --masterkeyFile ${CONFIG_DIR}/.masterkey --config ${CONFIG_DIR}/config.yaml
systemctl restart zitadel-api zitadel-login
EOF
chmod +x ~/zitadel-rerun.sh
msg_ok "Bash script for rerunning Zitadel after changing Zitadel config.yaml"

motd_ssh
customize
cleanup_lxc
