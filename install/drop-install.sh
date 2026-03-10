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
# DOWNLOAD & DEPLOY APPLICATION
# =============================================================================

fetch_and_deploy_gh_release "drop" "Drop-OSS/drop" "tarball" "latest" "/opt/drop"

# =============================================================================
# BUILD APPLICATION
# =============================================================================

msg_info "Installing Application Dependencies"
cd /opt/drop || exit
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
$STD pnpm install --frozen-lockfile
$STD pnpm prisma generate
msg_ok "Installed Application Dependencies"

msg_info "Building Application"
cd /opt/drop || exit
$STD pnpm build
msg_ok "Built Application"

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

# Security
NUXT_SESSION_PASSWORD="${SECRET_KEY}"

# Optional: External URL (uncomment and configure if needed)
# NUXT_PUBLIC_URL="http://${LOCAL_IP}:3000"
EOF

msg_ok "Configured Drop"

# =============================================================================
# DATABASE MIGRATION
# =============================================================================

msg_info "Running Database Migrations"
cd /opt/drop || exit
$STD pnpm prisma migrate deploy
msg_ok "Ran Database Migrations"

# =============================================================================
# NGINX CONFIGURATION
# =============================================================================

msg_info "Configuring NGINX"
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
Environment="PATH=/root/.local/share/pnpm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/root/.local/share/pnpm/pnpm run start
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
