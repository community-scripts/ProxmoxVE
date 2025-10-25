#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatcMmon/PatchMon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
PG_VERSION="17" setup_postgresql

msg_info "Setup PostgreSQL Database"
DB_NAME=patchmon_db
DB_USER=patchmon_usr
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
{
  echo "PatchMon Credentials"
  echo "PatchMon Database Name: $DB_NAME"
  echo "PatchMon Database User: $DB_USER"
  echo "PatchMon Database Password: $DB_PASS"
} >>~/patchmon.creds
msg_ok "Setup PostgreSQL Database"

fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "tarball" "latest" "/opt/patchmon"

msg_info "Configuring PatchMon"
cd /opt/patchmon
export NODE_ENV=production
$STD npm install --no-audit --no-fund --no-save --ignore-scripts
cd /opt/patchmon/backend
$STD npm install --no-audit --no-fund --no-save --ignore-scripts
cd /opt/patchmon/frontend
$STD npm install --include=dev --no-audit --no-fund --no-save --ignore-scripts
$STD npm run build

JWT_SECRET="$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
cat <<EOF >/opt/patchmon/backend/.env
# Database Configuration
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
PY_THRESHOLD=3M_DB_CONN_MAX_ATTEMPTS=30
PM_DB_CONN_WAIT_INTERVAL=2

# JWT Configuration
JWT_SECRET="$JWT_SECRET"
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
PORT=3399
NODE_ENV=production

# API Configuration
API_VERSION=v1

# CORS Configuration
CORS_ORIGIN="http://$LOCAL_IP"

# Session Configuration
SESSION_INACTIVITY_TIMEOUT_MINUTES=30

# User Configuration
DEFAULT_USER_ROLE=user

# Rate Limiting (times in milliseconds)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=5000
AUTH_RATE_LIMIT_WINDOW_MS=600000
AUTH_RATE_LIMIT_MAX=500
AGENT_RATE_LIMIT_WINDOW_MS=60000
AGENT_RATE_LIMIT_MAX=1000

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Logging
LOG_LEVEL=info
ENABLE_LOGGING=true

# TFA Configuration
TFA_REMEMBER_ME_EXPIRES_IN=30d
TFA_MAX_REMEMBER_SESSIONS=5
TFA_SUSPICIOUS_ACTIVITY_THRESHOLD=3
EOF

cat <<EOF >/opt/patchmon/frontend/.env
VITE_API_URL=http://$LOCAL_IP/api/v1
VITE_APP_NAME=PatchMon
VITE_APP_VERSION=1.3.0
EOF

cd /opt/patchmon/backend
$STD npx prisma migrate deploy
$STD npx prisma generate
msg_ok "Configured PatchMon"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/patchmon.conf
server {
    listen 80;
    server_name $LOCAL_IP;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Frontend
    location / {
        root /opt/patchmon/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }

    # Bull Board proxy
    location /bullboard {
        proxy_pass http://127.0.0.1:3399;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Cookie \$http_cookie;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
 
        # Enable cookie passthrough
        proxy_pass_header Set-Cookie;
        proxy_cookie_path / /;
 
        # Preserve original client IP
        proxy_set_header X-Original-Forwarded-For \$http_x_forwarded_for;
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:3399;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
 
        # Preserve original client IP
        proxy_set_header X-Original-Forwarded-For \$http_x_forwarded_for;
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Static assets caching (exclude Bull Board assets)
    location ~* ^/(?!bullboard).*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /opt/patchmon/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
 
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3399/health;
        access_log off;
    }
}
EOF
ln -sf /etc/nginx/sites-available/patchmon.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/patchmon-server.service
[Unit]
Description=PatchMon Service
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/patchmon/backend
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=/usr/bin:/usr/local/bin
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/patchmon

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now patchmon-server
msg_ok "Created and started service"

msg_info "Updating settings"
cat <<EOF >/opt/patchmon/backend/update-settings.js
const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');
const prisma = new PrismaClient();

async function updateSettings() {
  try {
    const existingSettings = await prisma.settings.findFirst();

    const settingsData = {
      id: uuidv4(),
      server_url: 'http://$LOCAL_IP',
      server_protocol: 'http',
      server_host: '$LOCAL_IP',
      server_port: 3399,
      update_interval: 60,
      auto_update: true,
      signup_enabled: false,
      ignore_ssl_self_signed: false,
      updated_at: new Date()
    };

  if (existingSettings) {
    // Update existing settings
    await prisma.settings.update({
      where: { id: existingSettings.id },
      data: settingsData
    });
  } else {
    // Create new settings record
    await prisma.settings.create({
      data: settingsData
    });
  }

  console.log('✅ Database settings updated successfully');
  } catch (error) {
    console.error('❌ Error updating settings:', error.message);
    process.exit(1);
  } finally {
    await prisma.\$disconnect();
  }
}

updateSettings();
EOF

cd /opt/patchmon/backend
$STD node update-settings.js
msg_ok "Settings updated successfully"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
