#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Termix-SSH/Termix

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
  nginx \
  openssl \
  gettext-base
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "termix" "Termix-SSH/Termix"

msg_info "Building Frontend"
cd /opt/termix
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
find public/fonts -name "*.ttf" ! -name "*Regular.ttf" ! -name "*Bold.ttf" ! -name "*Italic.ttf" -delete 2>/dev/null || true
$STD npm install --ignore-scripts --force
$STD npm cache clean --force
$STD npm run build
msg_ok "Built Frontend"

msg_info "Building Backend"
$STD npm rebuild better-sqlite3 --force
$STD npm run build:backend
msg_ok "Built Backend"

msg_info "Setting up Node Dependencies"
cd /opt/termix
$STD npm ci --only=production --ignore-scripts --force
$STD npm rebuild better-sqlite3 bcryptjs --force
$STD npm cache clean --force
msg_ok "Set up Node Dependencies"

msg_info "Setting up Directories"
mkdir -p /opt/termix/data \
  /opt/termix/uploads \
  /opt/termix/html \
  /opt/termix/nginx \
  /opt/termix/nginx/logs \
  /opt/termix/nginx/cache \
  /opt/termix/nginx/client_body

cp -r /opt/termix/dist/* /opt/termix/html/ 2>/dev/null || true
cp -r /opt/termix/src/locales /opt/termix/html/locales 2>/dev/null || true
cp -r /opt/termix/public/fonts /opt/termix/html/fonts 2>/dev/null || true
msg_ok "Set up Directories"

msg_info "Configuring Nginx"
curl -fsSL "https://raw.githubusercontent.com/Termix-SSH/Termix/main/docker/nginx.conf" -o /etc/nginx/nginx.conf
sed -i '/^master_process/d' /etc/nginx/nginx.conf
sed -i '/^pid \/app\/nginx/d' /etc/nginx/nginx.conf
sed -i 's|/app/html|/opt/termix/html|g' /etc/nginx/nginx.conf
sed -i 's|/app/nginx|/opt/termix/nginx|g' /etc/nginx/nginx.conf
sed -i 's|listen ${PORT};|listen 80;|g' /etc/nginx/nginx.conf

rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/termix.service
[Unit]
Description=Termix Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/termix
Environment=NODE_ENV=production
Environment=DATA_DIR=/opt/termix/data
ExecStart=/usr/bin/node /opt/termix/dist/backend/backend/starter.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now termix
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
