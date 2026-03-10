#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/community-unscripted/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Drop-OSS/drop | Docs: https://docs-next.droposs.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES
# =============================================================================

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  nginx \
  build-essential \
  pkg-config \
  libssl-dev \
  libpq-dev
msg_ok "Installed Dependencies"

# =============================================================================
# SETUP RUNTIMES & DATABASES
# =============================================================================

NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs

PG_VERSION="17" setup_postgresql
PG_DB_NAME="drop" PG_DB_USER="drop" setup_postgresql_db

get_lxc_ip

# =============================================================================
# DOWNLOAD & BUILD APPLICATION
# =============================================================================

msg_info "Cloning Drop Repository"
$STD git clone --branch develop --recurse-submodules https://github.com/Drop-OSS/drop.git /opt/drop
cd /opt/drop || exit
$STD git submodule update --init --recursive
msg_ok "Cloned Drop Repository"

msg_info "Installing Application Dependencies"
cd /opt/drop || exit
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
$STD pnpm install
msg_ok "Installed Application Dependencies"

msg_info "Building Drop Application"
cd /opt/drop || exit
$STD pnpm run build
msg_ok "Built Drop Application"

# =============================================================================
# BUILD TORRENTIAL (Rust component)
# =============================================================================

msg_info "Installing Rust"
$STD curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="/root/.cargo/bin:$PATH"
msg_ok "Installed Rust"

msg_info "Building Torrential"
cd /opt/drop/torrential || exit
$STD cargo build --release
msg_ok "Built Torrential"

# =============================================================================
# CONFIGURATION
# =============================================================================

msg_info "Configuring Drop"
cd /opt/drop || exit

# Generate a random secret for the application
SECRET_KEY=$(openssl rand -hex 32)

cat <<EOF >/opt/drop/.env
# Database Configuration
DATABASE_URL="postgresql://drop:${PG_DB_PASS}@localhost:5432/drop"

# Server Configuration
HOST="0.0.0.0"
PORT=4000
EXTERNAL_URL="http://${LOCAL_IP}:3000"

# NGINX Configuration
NGINX_CONFIG=./nginx.conf

# Data Directory
DATA=./data

# Security
NUXT_SESSION_PASSWORD="${SECRET_KEY}"
EOF

msg_ok "Configured Drop"

# =============================================================================
# DATABASE MIGRATION
# =============================================================================

msg_info "Running Database Migrations"
cd /opt/drop || exit
$STD npm install prisma@7.3.0 dotenv
$STD DATABASE_URL="postgresql://drop:${PG_DB_PASS}@localhost:5432/drop" npx prisma migrate deploy
msg_ok "Ran Database Migrations"

# =============================================================================
# NGINX CONFIGURATION
# =============================================================================

msg_info "Configuring NGINX"
cp /opt/drop/build/nginx.conf /opt/drop/nginx.conf

cat <<EOF >/etc/nginx/sites-available/drop
server {
    listen 3000;
    server_name _;

    client_max_body_size 0;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

$STD rm -f /etc/nginx/sites-enabled/default
$STD ln -sf /etc/nginx/sites-available/drop /etc/nginx/sites-enabled/drop
msg_ok "Configured NGINX"

# =============================================================================
# CREATE SYSTEMD SERVICE
# =============================================================================

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/drop.service
[Unit]
Description=Drop - Game Distribution Platform
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/drop
Environment="PNPM_HOME=/root/.local/share/pnpm"
Environment="PATH=/root/.cargo/bin:/root/.local/share/pnpm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EnvironmentFile=/opt/drop/.env
ExecStart=/usr/bin/node ./.output/server/index.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now drop
msg_ok "Created Service"

# =============================================================================
# START NGINX
# =============================================================================

msg_info "Starting NGINX"
systemctl enable -q --now nginx
msg_ok "Started NGINX"

# =============================================================================
# CLEANUP & FINALIZATION
# =============================================================================

motd_ssh
customize
cleanup_lxc
