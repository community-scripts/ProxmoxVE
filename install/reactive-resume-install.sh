#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream | Rewrite: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rxresume.org | Github: https://github.com/amruthpillai/reactive-resume

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="16" setup_postgresql
PG_DB_NAME="reactive_resume" PG_DB_USER="reactive_resume" setup_postgresql_db
NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs

msg_info "Installing Dependencies"
$STD apt install -y chromium
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "reactive-resume" "amruthpillai/reactive-resume" "tarball"

msg_info "Building Reactive Resume (Patience)"
cd /opt/reactive-resume
export NODE_ENV="production"
export CI="true"
$STD pnpm install --frozen-lockfile
$STD pnpm run build
mkdir -p /opt/reactive-resume/data
msg_ok "Built Reactive Resume"

msg_info "Configuring Reactive Resume"
AUTH_SECRET=$(openssl rand -hex 32)

cat <<EOF >/opt/reactive-resume/.env
# Reactive Resume v5 Configuration
NODE_ENV=production
PORT=3000

# Public URL (change to your FQDN when using a reverse proxy)
APP_URL=http://${LOCAL_IP}:3000

# Database
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}

# Authentication Secret (do not change after initial setup)
AUTH_SECRET=${AUTH_SECRET}

# Printer (headless Chromium for PDF generation)
PRINTER_ENDPOINT=http://localhost:9222

# Storage: uses local filesystem (/opt/reactive-resume/data) when S3 is not configured
# S3_ACCESS_KEY_ID=
# S3_SECRET_ACCESS_KEY=
# S3_REGION=us-east-1
# S3_ENDPOINT=
# S3_BUCKET=
# S3_FORCE_PATH_STYLE=false

# Email (optional, logs to console if not configured)
# SMTP_HOST=
# SMTP_PORT=465
# SMTP_USER=
# SMTP_PASS=
# SMTP_FROM=Reactive Resume <noreply@localhost>

# OAuth (optional)
# GITHUB_CLIENT_ID=
# GITHUB_CLIENT_SECRET=
# GOOGLE_CLIENT_ID=
# GOOGLE_CLIENT_SECRET=

# Feature Flags
# FLAG_DISABLE_SIGNUPS=false
# FLAG_DISABLE_EMAIL_AUTH=false
EOF
msg_ok "Configured Reactive Resume"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/chromium-printer.service
[Unit]
Description=Headless Chromium for Reactive Resume PDF generation
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/chromium --headless --disable-gpu --no-sandbox --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/reactive-resume.service
[Unit]
Description=Reactive Resume
After=network.target postgresql.service chromium-printer.service
Wants=postgresql.service chromium-printer.service

[Service]
WorkingDirectory=/opt/reactive-resume
EnvironmentFile=/opt/reactive-resume/.env
ExecStart=/usr/bin/node .output/server/index.mjs
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now chromium-printer.service reactive-resume.service
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
