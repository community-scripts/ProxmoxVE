#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bluewave-labs/Checkmate

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
  openssl \
  nginx
msg_ok "Installed Dependencies"

MONGO_VERSION="8.0" setup_mongodb
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "checkmate" "bluewave-labs/Checkmate"

msg_info "Configuring Checkmate"
JWT_SECRET="$(openssl rand -hex 32)"
cat <<EOF >/opt/checkmate/server/.env
CLIENT_HOST="http://${LOCAL_IP}"
JWT_SECRET="${JWT_SECRET}"
DB_CONNECTION_STRING="mongodb://localhost:27017/checkmate_db"
TOKEN_TTL="99d"
ORIGIN="${LOCAL_IP}"
LOG_LEVEL="info"
SERVER_HOST=0.0.0.0
SERVER_PORT=52345
EOF
cat <<EOF >/opt/checkmate/client/.env.local
VITE_APP_API_BASE_URL="/api/v1"
UPTIME_APP_API_BASE_URL="/api/v1"
VITE_APP_LOG_LEVEL="warn"
EOF
msg_ok "Configured Checkmate"

msg_info "Installing Checkmate Server"
cd /opt/checkmate/server
$STD npm install
$STD npm run build
msg_ok "Installed Checkmate Server"

msg_info "Installing Checkmate Client"
cd /opt/checkmate/client
$STD npm install
VITE_APP_API_BASE_URL="/api/v1" UPTIME_APP_API_BASE_URL="/api/v1" VITE_APP_LOG_LEVEL="warn" $STD npm run build
msg_ok "Installed Checkmate Client"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/checkmate-server.service
[Unit]
Description=Checkmate Server
After=network.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/checkmate/server
EnvironmentFile=/opt/checkmate/server/.env
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/checkmate-client.service
[Unit]
Description=Checkmate Client
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/checkmate/client
ExecStart=/usr/bin/npm run preview -- --host 127.0.0.1 --port 5173
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now checkmate-server
$STD systemctl enable -q --now checkmate-client
msg_ok "Created Services"

msg_info "Configuring Nginx Reverse Proxy"
cat <<EOF >/etc/nginx/sites-available/checkmate
server {
  listen 80 default_server;
  server_name _;
  
  client_max_body_size 100M;

  # Client UI
  location / {
    proxy_pass http://127.0.0.1:5173;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }

  # API Server
  location /api/v1/ {
    proxy_pass http://127.0.0.1:52345/api/v1/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF
ln -sf /etc/nginx/sites-available/checkmate /etc/nginx/sites-enabled/checkmate
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured Nginx Reverse Proxy"

motd_ssh
customize
cleanup_lxc
