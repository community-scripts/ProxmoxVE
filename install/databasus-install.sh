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
  valkey \
  mariadb-client \
  rclone
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
setup_go
NODE_VERSION="24" setup_nodejs

msg_info "Installing Database Clients"
# Create PostgreSQL version symlinks for compatibility
for v in 12 13 14 15 16 18; do
  ln -sf /usr/lib/postgresql/17 /usr/lib/postgresql/$v
done
# Install MongoDB Database Tools via direct .deb (no APT repo for Debian 13)
[[ "$(get_os_info id)" == "ubuntu" ]] && MONGO_DIST="ubuntu2204" || MONGO_DIST="debian12"
MONGO_VERSION=$(get_latest_gh_tag "mongodb/mongo-tools" "100." || echo "100.14.1")
fetch_and_deploy_from_url "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-${MONGO_DIST}-x86_64-${MONGO_VERSION}.deb"
mkdir -p /usr/local/mongodb-database-tools/bin
[[ -f /usr/bin/mongodump ]] && ln -sf /usr/bin/mongodump /usr/local/mongodb-database-tools/bin/mongodump
[[ -f /usr/bin/mongorestore ]] && ln -sf /usr/bin/mongorestore /usr/local/mongodb-database-tools/bin/mongorestore
# Create MariaDB and MySQL client symlinks for compatibility
mkdir -p /usr/local/mariadb-{10.6,12.1}/bin /usr/local/mysql-{5.7,8.0,8.4,9}/bin
for dir in /usr/local/mariadb-{10.6,12.1}/bin; do
  ln -sf /usr/bin/mariadb-dump "$dir/mariadb-dump"
  ln -sf /usr/bin/mariadb "$dir/mariadb"
done
for dir in /usr/local/mysql-{5.7,8.0,8.4,9}/bin; do
  ln -sf /usr/bin/mariadb-dump "$dir/mysqldump"
  ln -sf /usr/bin/mariadb "$dir/mysql"
done
msg_ok "Installed Database Clients"

fetch_and_deploy_gh_release "databasus" "databasus/databasus" "tarball" "latest" "/opt/databasus"

msg_info "Building Databasus (Patience)"
cd /opt/databasus/frontend
$STD npm ci
$STD npm run build
cd /opt/databasus/backend
$STD go mod tidy
$STD go mod download
$STD go install github.com/swaggo/swag/cmd/swag@latest
$STD /root/go/bin/swag init -g cmd/main.go -o swagger
$STD env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o databasus ./cmd/main.go
mv /opt/databasus/backend/databasus /opt/databasus/databasus
mkdir -p /databasus-data/{pgdata,temp,backups,data,logs}
mkdir -p /opt/databasus/ui/build
mkdir -p /opt/databasus/migrations
cp -r /opt/databasus/frontend/dist/* /opt/databasus/ui/build/
cp -r /opt/databasus/backend/migrations/* /opt/databasus/migrations/
chown -R postgres:postgres /databasus-data
msg_ok "Built Databasus"

msg_info "Configuring Databasus"
JWT_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
# Install goose for migrations
$STD go install github.com/pressly/goose/v3/cmd/goose@latest
ln -sf /root/go/bin/goose /usr/local/bin/goose
cat <<EOF >/opt/databasus/.env
# Environment
ENV_MODE=production

# Server
SERVER_PORT=4005
SERVER_HOST=0.0.0.0

# Database
DATABASE_DSN=host=localhost user=postgres password=postgres dbname=databasus port=5432 sslmode=disable
DATABASE_URL=postgres://postgres:postgres@localhost:5432/databasus?sslmode=disable

# Migrations
GOOSE_DRIVER=postgres
GOOSE_DBSTRING=postgres://postgres:postgres@localhost:5432/databasus?sslmode=disable
GOOSE_MIGRATION_DIR=/opt/databasus/migrations

# Valkey (Redis-compatible cache)
VALKEY_HOST=localhost
VALKEY_PORT=6379

# Security
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# Paths
DATA_DIR=/databasus-data/data
BACKUP_DIR=/databasus-data/backups
LOG_DIR=/databasus-data/logs
EOF
chown postgres:postgres /opt/databasus/.env
chmod 600 /opt/databasus/.env
msg_ok "Configured Databasus"

msg_info "Configuring Valkey"
cat <<EOF >/etc/valkey/valkey.conf
port 6379
bind 127.0.0.1
protected-mode yes
save ""
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF
systemctl enable -q --now valkey-server
systemctl restart valkey-server
msg_ok "Configured Valkey"

msg_info "Creating Database"
# Configure PostgreSQL to allow local password auth for databasus
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
After=network.target postgresql.service valkey.service
Requires=postgresql.service valkey.service

[Service]
Type=simple
WorkingDirectory=/opt/databasus
EnvironmentFile=/opt/databasus/.env
ExecStart=/opt/databasus/databasus
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl daemon-reload
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
ln -sf /etc/nginx/sites-available/databasus /etc/nginx/sites-enabled/databasus
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
$STD systemctl enable -q --now nginx
$STD systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
