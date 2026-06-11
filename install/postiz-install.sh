#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gitroomhq/postiz-app

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
  python3 \
  redis-server \
  nginx
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="postiz" PG_DB_USER="postiz" setup_postgresql_db
NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "temporal" "temporalio/cli" "prebuild" "latest" "/opt/temporal" "temporal_cli_*_linux_amd64.tar.gz"
chmod +x /opt/temporal/temporal

fetch_and_deploy_gh_release "postiz" "gitroomhq/postiz-app" "tarball"

msg_info "Installing pnpm"
PNPM_VERSION=$(sed -n 's/.*"packageManager":\s*"pnpm@\([^"]*\)".*/\1/p' /opt/postiz/package.json)
$STD npm install -g "pnpm@${PNPM_VERSION}"
msg_ok "Installed pnpm"

msg_info "Configuring Application"
JWT_SECRET=$(openssl rand -base64 32)
mkdir -p /opt/postiz/uploads
cat <<EOF >/opt/postiz/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
REDIS_URL=redis://localhost:6379
JWT_SECRET=${JWT_SECRET}
MAIN_URL=http://${LOCAL_IP}
FRONTEND_URL=http://${LOCAL_IP}
NEXT_PUBLIC_BACKEND_URL=http://${LOCAL_IP}/api
BACKEND_INTERNAL_URL=http://localhost:3000
NOT_SECURED=true
TEMPORAL_ADDRESS=localhost:7233
IS_GENERAL=true
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/opt/postiz/uploads
NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads
NX_ADD_PLUGINS=false
EOF
msg_ok "Configured Application"

msg_info "Building Application"
cd /opt/postiz
set -a && source /opt/postiz/.env && set +a
export NODE_OPTIONS="--max-old-space-size=4096"
$STD pnpm install
$STD pnpm run build
unset NODE_OPTIONS
msg_ok "Built Application"

msg_info "Running Database Migrations"
cd /opt/postiz
set -a && source /opt/postiz/.env && set +a
$STD pnpm run prisma-db-push
msg_ok "Ran Database Migrations"

msg_info "Creating Services"
PNPM_BIN="$(command -v pnpm)"

cat <<EOF >/etc/systemd/system/postiz-temporal.service
[Unit]
Description=Temporal Dev Server (Postiz)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/temporal/temporal server start-dev --db-filename /opt/temporal/temporal.db --log-format json --log-level warn
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/postiz-backend.service
[Unit]
Description=Postiz Backend
After=network.target postgresql.service redis-server.service postiz-temporal.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/postiz
EnvironmentFile=/opt/postiz/.env
ExecStart=${PNPM_BIN} run start:prod:backend
Environment=NODE_OPTIONS=--max-old-space-size=512
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/postiz-frontend.service
[Unit]
Description=Postiz Frontend
After=network.target postiz-backend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/postiz
EnvironmentFile=/opt/postiz/.env
Environment=PORT=4200
ExecStart=${PNPM_BIN} run start:prod:frontend
Environment=NODE_OPTIONS=--max-old-space-size=512
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/postiz-orchestrator.service
[Unit]
Description=Postiz Orchestrator
After=network.target postiz-temporal.service postiz-backend.service
Requires=postiz-temporal.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/postiz
EnvironmentFile=/opt/postiz/.env
ExecStart=${PNPM_BIN} run start:prod:orchestrator
Environment=NODE_OPTIONS=--max-old-space-size=384
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now redis-server postiz-temporal postiz-backend postiz-frontend postiz-orchestrator
msg_ok "Created Services"

msg_info "Creating Helper Scripts"
cat <<'EOF' >/usr/local/bin/postiz-rebuild
#!/usr/bin/env bash
echo "=== Postiz Rebuild ==="
echo "Stopping services..."
systemctl stop postiz-orchestrator postiz-frontend postiz-backend

cd /opt/postiz
set -a && source /opt/postiz/.env && set +a
export NODE_OPTIONS="--max-old-space-size=4096"

echo "Building application (this may take a while)..."
pnpm run build
BUILD_RC=$?
unset NODE_OPTIONS

if [[ $BUILD_RC -ne 0 ]]; then
  echo "ERROR: Build failed! Check the output above."
  echo "Starting services with previous build..."
  systemctl start postiz-backend postiz-frontend postiz-orchestrator
  exit 1
fi

echo "Running database migrations..."
pnpm run prisma-db-push

echo "Starting services..."
systemctl start postiz-backend postiz-frontend postiz-orchestrator
echo "=== Rebuild complete ==="
EOF
chmod +x /usr/local/bin/postiz-rebuild
msg_ok "Created Helper Scripts"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/postiz
server {
  listen 80 default_server;
  server_name _;

  client_max_body_size 100M;

  gzip on;
  gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

  location /api/ {
    proxy_pass http://127.0.0.1:3000/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Reload \$http_reload;
    proxy_set_header Onboarding \$http_onboarding;
    proxy_set_header Activate \$http_activate;
    proxy_set_header Auth \$http_auth;
    proxy_set_header Showorg \$http_showorg;
    proxy_set_header Impersonate \$http_impersonate;
    proxy_set_header Accept-Language \$http_accept_language;
  }

  location /uploads/ {
    alias /opt/postiz/uploads/;
  }

  location / {
    proxy_pass http://127.0.0.1:4200/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Reload \$http_reload;
    proxy_set_header Onboarding \$http_onboarding;
    proxy_set_header Activate \$http_activate;
    proxy_set_header Auth \$http_auth;
    proxy_set_header Showorg \$http_showorg;
    proxy_set_header Impersonate \$http_impersonate;
    proxy_set_header Accept-Language \$http_accept_language;
    proxy_set_header i18next \$http_i18next;
  }
}
EOF
ln -sf /etc/nginx/sites-available/postiz /etc/nginx/sites-enabled/postiz
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl enable -q nginx
systemctl reload -q nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
