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
ZITADEL_USER="zitadel"
ZITADEL_GROUP="zitadel"
POSTGRES_VERSION="17"
DB_NAME="zitadel"
DB_USER="zitadel"
DB_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
POSTGRES_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
MASTERKEY="$(openssl rand -base64 32 | tr -d '=/+' | head -c 32)"
#NODE_VERSION="22"
GO_VERSION="1.24.0"
API_PORT="8080"
LOGIN_PORT="3000"

# Detect server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')


msg_info "Installing Dependencies (Patience)"
$STD apt install -y ca-certificates \
    curl \
    wget \
    git \
    build-essential \
    gnupg \
    lsb-release \
    openssl \
    apt-transport-https
#    postgresql-common
msg_ok "Installed Dependecies"

# Create zitadel user
msg_info "Creating zitadel system user"
groupadd --system "${ZITADEL_GROUP}"
useradd --system --gid "${ZITADEL_GROUP}" --shell /bin/bash --home-dir "${ZITADEL_DIR}" "${ZITADEL_USER}"
msg_ok "Created zitadel system user"

# fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "tarball" "latest"
# chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}"

fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "latest" "${ZITADEL_DIR}" "zitadel-linux-amd64.tar.gz"
# Might need to chmod +x "$ZITADEL_DIR/zitadel"

fetch_and_deploy_gh_release "login" "zitadel/zitadel" "prebuild" "latest" "${LOGIN_DIR}" "zitadel-login.tar.gz"
#mv "$LOGIN_DIR"/* "$ZITADEL_DIR/"
#rm -rf "$LOGIN_DIR"
# # The archive extracts to apps/login/ structure
# if [[ -d "$LOGIN_DIR/apps/login" ]]; then
    # mv "$LOGIN_DIR/apps/login"/* "$LOGIN_DIR/" 2>/dev/null || true
    # rm -rf "$LOGIN_DIR/apps"
# fi

chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}"
chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${LOGIN_DIR}"

#NODE_VERSION="24" NODE_MODULE="pnpm@latest" setup_nodejs
NODE_VERSION="24" setup_nodejs
#node apps/login/server.js

# Enable Corepack for pnpm (force to handle existing symlinks)
#corepack enable --install-directory /usr/local/bin
#export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
#$STD corepack enable

PG_VERSION="17" setup_postgresql

setup_go

msg_info "Configuring Postgresql"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_ADMIN_PASSWORD}';"
msg_ok "Configured PostgreSQL"


msg_info "Installing Zitadel"
cd "${ZITADEL_DIR}"
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && export COREPACK_ENABLE_DOWNLOAD_PROMPT=0 && corepack enable && pnpm install"
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && pnpm nx run-many --target generate"
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && pnpm nx run @zitadel/api:build"
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:\$PATH && pnpm nx run @zitadel/login:build"

mkdir -p ${ZITADEL_DIR}/apps/api/
# Update prod-default.yaml for network access
cat > "${ZITADEL_DIR}/apps/api/prod-default.yaml" <<EOF
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
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}/apps/api/prod-default.yaml"

mkdir -p ${LOGIN_DIR}/apps/login/
# Update Login V2 .env file
cat > "${LOGIN_DIR}/apps/login/.env" <<EOF
NEXT_PUBLIC_BASE_PATH=/ui/v2/login
EMAIL_VERIFICATION=false
ZITADEL_API_URL=http://${SERVER_IP}:${API_PORT}
ZITADEL_SERVICE_USER_TOKEN_FILE=../../login-client.pat
EOF

chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${LOGIN_DIR}/apps/login/.env"

# Update package.json to bind to 0.0.0.0 instead of 127.0.0.1
sed -i 's/"prod": "cd \.\/\.next\/standalone && HOSTNAME=127\.0\.0\.1/"prod": "cd .\/\.next\/standalone \&\& HOSTNAME=0.0.0.0/g' "${LOGIN_DIR}/apps/login/package.json"

# Initialize database as zitadel user (no masterkey needed for init)
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && \
	# ./.artifacts/bin/linux/amd64/zitadel.local init \
	# --config apps/api/prod-default.yaml"
sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && \
	./zitadel init \
	--config apps/api/prod-default.yaml"

# Run setup phase as zitadel user (with masterkey and steps)
# sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && \
	# ./.artifacts/bin/linux/amd64/zitadel.local setup \
	# --config apps/api/prod-default.yaml \
	# --steps apps/api/prod-default.yaml \
	# --masterkey '${MASTERKEY}'"
sudo -u "${ZITADEL_USER}" bash -c "cd ${ZITADEL_DIR} && export PATH=/usr/local/bin:/usr/local/go/bin:\$PATH && \
	./zitadel setup \
	--config apps/api/prod-default.yaml \
	--steps apps/api/prod-default.yaml \
	--masterkey '${MASTERKEY}'"


# Create .env.secrets file
cat > "${ZITADEL_DIR}/.env.secrets" <<EOF
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
chmod 600 "${ZITADEL_DIR}/.env.secrets"
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}/.env.secrets"
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
EnvironmentFile=${ZITADEL_DIR}/.env.secrets
Environment="PATH=/usr/local/bin:/usr/local/go/bin:/usr/bin:/bin"
#ExecStart=${ZITADEL_DIR}/.artifacts/bin/linux/amd64/zitadel.local start --config ${ZITADEL_DIR}/apps/api/prod-default.yaml --masterkey \${ZITADEL_MASTERKEY}
ExecStart=${ZITADEL_DIR}/zitadel start --config ${ZITADEL_DIR}/apps/api/prod-default.yaml --masterkey \${ZITADEL_MASTERKEY}
Restart=always
RestartSec=10
StandardOutput=append:${ZITADEL_DIR}/logs/api.log
StandardError=append:${ZITADEL_DIR}/logs/api-error.log

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
EnvironmentFile="${LOGIN_DIR}/apps/login/.env"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="NODE_ENV=production"
#ExecStart=pnpm nx run @zitadel/login:prod
ExecStart=npm run start
Restart=always
RestartSec=10
StandardOutput=append:${ZITADEL_DIR}/logs/login.log
StandardError=append:${ZITADEL_DIR}/logs/login-error.log

[Install]
WantedBy=multi-user.target
EOF

# Create logs directory
mkdir -p "${ZITADEL_DIR}/logs"
chown -R "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}/logs"

# Reload systemd
systemctl daemon-reload


# Enable and start API service
systemctl enable -q --now zitadel-api.service

# Wait for API to start
sleep 10

# Enable and start Login service
systemctl enable -q --now zitadel-login.service
msg_ok "Created Services"

msg_info "Saving Credentials"
# Create credentials file
cat > "${ZITADEL_DIR}/INSTALLATION_INFO.txt" <<EOF
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
   - Set ExternalSecure: true in prod-default.yaml
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
chmod 600 "${ZITADEL_DIR}/INSTALLATION_INFO.txt"
chown "${ZITADEL_USER}:${ZITADEL_GROUP}" "${ZITADEL_DIR}/INSTALLATION_INFO.txt"
msg_ok "Saved Credentials"

motd_ssh
customize
cleanup_lxc
