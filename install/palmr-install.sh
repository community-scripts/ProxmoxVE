#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kyantech/Palmr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up MinIO"
curl -fsSL "https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.2024-10-13T13-34-11Z" -o /usr/local/bin/minio
chmod +x /usr/local/bin/minio
curl -fsSL "https://dl.min.io/client/mc/release/linux-amd64/mc" -o /usr/local/bin/mc
chmod +x /usr/local/bin/mc
msg_ok "Set up MinIO"

fetch_and_deploy_gh_release "Palmr" "kyantech/Palmr" "tarball" "latest" "/opt/palmr"
NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/palmr/package.json)" setup_nodejs

msg_info "Configuring Palmr"
mkdir -p /opt/palmr_data/{minio-data,prisma,uploads,temp-uploads}
MINIO_PASSWORD="$(openssl rand -hex 16)"

cat <<EOF >/opt/palmr_data/.minio-credentials
S3_ENDPOINT=127.0.0.1
S3_PORT=9379
S3_ACCESS_KEY=palmr-admin
S3_SECRET_KEY=${MINIO_PASSWORD}
S3_BUCKET_NAME=palmr-files
S3_REGION=us-east-1
S3_USE_SSL=false
S3_FORCE_PATH_STYLE=true
EOF

cd /opt/palmr/apps/server
cat <<EOF >.env
ENABLE_S3=false
STORAGE_URL=http://$(hostname -I | awk '{print $1}'):9379
DATABASE_URL=file:/opt/palmr_data/prisma/palmr.db
DISABLE_FILESYSTEM_ENCRYPTION=true
ENCRYPTION_KEY=$(openssl rand -hex 32)
EOF
$STD pnpm install
$STD npx prisma generate
$STD npx prisma migrate deploy
$STD npx prisma db push
$STD pnpm db:seed
$STD pnpm build

cd /opt/palmr/apps/web
echo "API_BASE_URL=http://127.0.0.1:3333" >.env
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
$STD pnpm install
$STD pnpm build

{
  echo "Palmr Credentials"
  echo "MinIO User: palmr-admin"
  echo "MinIO Password: $MINIO_PASSWORD"
} >>~/palmr.creds
msg_ok "Configured Palmr"

msg_info "Creating Services"
useradd -d /opt/palmr_data -M -s /usr/sbin/nologin -U palmr
chown -R palmr:palmr /opt/palmr_data /opt/palmr

cat <<EOF >/etc/systemd/system/palmr-minio.service
[Unit]
Description=Palmr MinIO Service
After=network.target

[Service]
Type=simple
User=palmr
Group=palmr
Environment="MINIO_ROOT_USER=palmr-admin"
Environment="MINIO_ROOT_PASSWORD=${MINIO_PASSWORD}"
ExecStart=/usr/local/bin/minio server /opt/palmr_data/minio-data --address 0.0.0.0:9379 --console-address 0.0.0.0:9378
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/palmr-backend.service
[Unit]
Description=Palmr Backend Service
After=network.target palmr-minio.service
Requires=palmr-minio.service

[Service]
Type=simple
User=palmr
Group=palmr
WorkingDirectory=/opt/palmr/apps/server
ExecStart=/usr/bin/node /opt/palmr/apps/server/dist/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/palmr-frontend.service
[Unit]
Description=Palmr Frontend Service
After=network.target palmr-backend.service
Requires=palmr-backend.service

[Service]
Type=simple
User=palmr
Group=palmr
WorkingDirectory=/opt/palmr/apps/web
Environment="NODE_ENV=production"
ExecStart=/usr/bin/pnpm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now palmr-minio
sleep 3
$STD mc alias set palmr http://127.0.0.1:9379 palmr-admin "$MINIO_PASSWORD"
$STD mc mb palmr/palmr-files --ignore-existing
systemctl enable -q --now palmr-backend palmr-frontend
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
