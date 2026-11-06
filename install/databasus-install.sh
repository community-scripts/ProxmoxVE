#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/databasus/databasus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  libedit2 \
  libgssapi-krb5-2 \
  libncurses6 \
  libreadline8t64
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

fetch_and_deploy_gh_release "databasus" "databasus/databasus" "tarball" "latest" "/opt/databasus"
GO_VERSION="$(grep -m1 '^go ' /opt/databasus/backend/go.mod | awk '{print $2}')" setup_go

msg_info "Building Databasus (Patience)"
RELEASE=$(cat ~/.databasus)
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd /opt/databasus/frontend
$STD corepack prepare pnpm@latest --activate
$STD pnpm install --frozen-lockfile
$STD env VITE_APP_VERSION="${RELEASE}" pnpm run build
cd /opt/databasus/backend
$STD env CGO_ENABLED=0 GOOS=linux GOARCH="$(arch_resolve)" go build -o /opt/databasus/databasus ./cmd/databasus
mkdir -p /opt/databasus/agent-binaries
for arch in amd64 arm64; do
  $STD env CGO_ENABLED=0 GOOS=linux GOARCH=$arch go build -ldflags "-X main.Version=${RELEASE}" -o /opt/databasus/agent-binaries/databasus-verification-agent-linux-$arch ./cmd/verification-agent
done
mkdir -p /databasus-data/{pgdata,temp,backups,data,logs}
mkdir -p /opt/databasus/ui/build
cp -r /opt/databasus/frontend/dist/* /opt/databasus/ui/build/
chown -R postgres:postgres /databasus-data
msg_ok "Built Databasus"

msg_info "Configuring Databasus"
cat <<EOF >/.env
ENV_MODE=production
APP_VERSION=${RELEASE}
DATABASE_DSN=host=localhost user=postgres password=postgres dbname=databasus port=5432 sslmode=disable
EOF
chmod 600 /.env
msg_ok "Configured Databasus"

msg_info "Creating Database"
PG_HBA="/etc/postgresql/17/main/pg_hba.conf"
if ! grep -q "databasus" "$PG_HBA"; then
  sed -i '/^local\s*all\s*all/i local   databasus   postgres                                trust' "$PG_HBA"
  sed -i '/^host\s*all\s*all\s*127/i host    databasus   postgres        127.0.0.1/32            trust' "$PG_HBA"
  systemctl reload postgresql
fi
$STD sudo -u postgres psql -c "CREATE DATABASE databasus;" 2>/dev/null || true
$STD sudo -u postgres psql -c "ALTER USER postgres WITH SUPERUSER CREATEROLE CREATEDB;" 2>/dev/null || true
msg_ok "Created Database"

msg_info "Creating Databasus Service"
cat <<EOF >/etc/systemd/system/databasus.service
[Unit]
Description=Databasus - Database Backup Management
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/databasus
EnvironmentFile=/.env
ExecStart=/opt/databasus/databasus
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now databasus
msg_ok "Created Databasus Service"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/databasus
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:4005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_buffering off;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
EOF
nginx_enable_site databasus
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
