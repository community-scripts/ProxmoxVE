#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rxresume.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
cd /tmp
curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio.deb -o minio.deb
$STD dpkg -i minio.deb
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs

msg_info "Setting up Database"
DB_USER="rxresume"
DB_NAME="rxresume"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
msg_ok "Set up Database"

MINIO_PASS=$(openssl rand -base64 48)
ACCESS_TOKEN=$(openssl rand -base64 48)
REFRESH_TOKEN=$(openssl rand -base64 48)
CHROME_TOKEN=$(openssl rand -hex 32)
LOCAL_IP=$(hostname -I | awk '{print $1}')
TAG=$(curl -fsSL https://api.github.com/repos/browserless/browserless/tags?per_page=1 | grep "name" | awk '{print substr($2, 3, length($2)-4) }')

fetch_and_deploy_gh_release "Reactive-Resume" "lazy-media/Reactive-Resume"

msg_info "Installing $APPLICATION"
cd /opt/"$APPLICATION"
export CI="true"
export PUPPETEER_SKIP_DOWNLOAD="true"
export NODE_ENV="production"
export NEXT_TELEMETRY_DISABLED=1
$STD pnpm install --frozen-lockfile
$STD pnpm run build
$STD pnpm run prisma:generate
msg_ok "Installed $APPLICATION"

msg_info "Installing Browserless (Patience)"
cd /tmp
curl -fsSL https://github.com/browserless/browserless/archive/refs/tags/v"$TAG".zip -o v"$TAG".zip
$STD unzip v"$TAG".zip
mv browserless-"$TAG" /opt/browserless
cd /opt/browserless
$STD npm install
rm -rf src/routes/{chrome,edge,firefox,webkit}
$STD node_modules/playwright-core/cli.js install --with-deps chromium
$STD npm install typescript --save-dev
$STD npm install esbuild --save-dev
$STD npm run build
$STD npm run build:function
$STD npm prune production
msg_ok "Installed Browserless"

msg_info "Configuring applications"
mkdir -p /opt/minio
cat <<EOF >/opt/minio/.env
MINIO_ROOT_USER="storageadmin"
MINIO_ROOT_PASSWORD="${MINIO_PASS}"
MINIO_VOLUMES=/opt/minio
MINIO_OPTS="--address :9000 --console-address 127.0.0.1:9001"
EOF
cat <<EOF >/opt/"$APPLICATION"/.env
NODE_ENV=production
PORT=3000
# for use behind a reverse proxy, use your FQDN for PUBLIC_URL and STORAGE_URL
PUBLIC_URL=http://${LOCAL_IP}:3000
STORAGE_URL=http://${LOCAL_IP}:9000/rxresume
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}?schema=public
ACCESS_TOKEN_SECRET=${ACCESS_TOKEN}
REFRESH_TOKEN_SECRET=${REFRESH_TOKEN}
CHROME_PORT=8080
CHROME_TOKEN=${CHROME_TOKEN}
CHROME_URL=ws://localhost:8080
CHROME_IGNORE_HTTPS_ERRORS=true
MAIL_FROM=noreply@locahost
# SMTP_URL=smtp://username:password@smtp.server.mail:587 #
STORAGE_ENDPOINT=localhost
STORAGE_PORT=9000
STORAGE_REGION=us-east-1
STORAGE_BUCKET=rxresume
STORAGE_ACCESS_KEY=storageadmin
STORAGE_SECRET_KEY=${MINIO_PASS}
STORAGE_USE_SSL=false
STORAGE_SKIP_BUCKET_CHECK=false

# GitHub (OAuth, Optional)
# GITHUB_CLIENT_ID=
# GITHUB_CLIENT_SECRET=
# GITHUB_CALLBACK_URL=http://localhost:5173/api/auth/github/callback

# Google (OAuth, Optional)
# GOOGLE_CLIENT_ID=
# GOOGLE_CLIENT_SECRET=
# GOOGLE_CALLBACK_URL=http://localhost:5173/api/auth/google/callback
EOF
cat <<EOF >/opt/browserless/.env
DEBUG=browserless*,-**:verbose
HOST=localhost
PORT=8080
TOKEN=${CHROME_TOKEN}
EOF
{
  echo "${APPLICATION} Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
  echo "Minio Root Password: ${MINIO_PASS}"
} >>~/"$APPLICATION".creds
msg_ok "Configured applications"

msg_info "Creating Services"
mkdir -p /etc/systemd/system/minio.service.d/
cat <<EOF >/etc/systemd/system/minio.service.d/override.conf
[Service]
User=root
Group=root
WorkingDirectory=/usr/local/bin
EnvironmentFile=/opt/minio/.env
EOF

cat <<EOF >/etc/systemd/system/"$APPLICATION".service
[Unit]
Description=${APPLICATION} Service
After=network.target postgresql.service minio.service
Wants=postgresql.service minio.service

[Service]
WorkingDirectory=/opt/${APPLICATION}
EnvironmentFile=/opt/${APPLICATION}/.env
ExecStart=/usr/bin/pnpm run start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/browserless.service
[Unit]
Description=Browserless service
After=network.target ${APPLICATION}.service

[Service]
WorkingDirectory=/opt/browserless
EnvironmentFile=/opt/browserless/.env
ExecStart=/usr/bin/npm run start
Restart=unless-stopped

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now minio.service "$APPLICATION".service browserless.service
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /tmp/v"$TAG".zip
rm -f /tmp/minio.deb
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
