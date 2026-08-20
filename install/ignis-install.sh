#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Nystik-gh/ignis

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "ignis" "Nystik-gh/ignis" "tarball"

msg_info "Building Ignis"
cd /opt/ignis
export NODE_OPTIONS="--max-old-space-size=4096"
export IGNIS_BUILD="$(cat ~/.ignis)"
$STD npm ci --ignore-scripts
$STD npm run build
$STD npm install -g @electron/asar
msg_ok "Built Ignis"

msg_info "Downloading Obsidian Web Assets"
mkdir -p /opt/ignis_data/{obsidian-app,vaults,data}
OBSIDIAN_VERSION=$(grep -oP 'OBSIDIAN_VERSION=\K[0-9.]+' /opt/ignis/apps/ignis-server/Dockerfile | head -n1)
[[ -z "$OBSIDIAN_VERSION" ]] && OBSIDIAN_VERSION="1.12.7"
curl -fsSL -o /tmp/obsidian.asar.gz "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian-${OBSIDIAN_VERSION}.asar.gz"
gunzip -f /tmp/obsidian.asar.gz
$STD asar extract /tmp/obsidian.asar /opt/ignis_data/obsidian-app
rm -f /tmp/obsidian.asar
echo "${OBSIDIAN_VERSION}" >/opt/ignis_data/obsidian.version
msg_ok "Downloaded Obsidian Web Assets"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ignis.service
[Unit]
Description=Ignis (Obsidian in the browser)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ignis
Environment=NODE_ENV=production
Environment=PORT=8080
Environment=VAULT_ROOT=/opt/ignis_data/vaults
Environment=DATA_ROOT=/opt/ignis_data/data
Environment=OBSIDIAN_ASSETS_PATH=/opt/ignis_data/obsidian-app
Environment=AUTO_CREATE_DEFAULT=true
ExecStart=/usr/bin/node /opt/ignis/apps/ignis-server/server/index.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ignis
msg_ok "Created Service"

msg_info "Generating Self-Signed Certificate"
create_self_signed_cert "ignis"
msg_ok "Generated Self-Signed Certificate"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/ignis.conf
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2 on;
    server_name _;

    ssl_certificate /etc/ssl/ignis/ignis.crt;
    ssl_certificate_key /etc/ssl/ignis/ignis.key;

    client_max_body_size 1024m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600s;
    }
}
EOF
ln -sf /etc/nginx/sites-available/ignis.conf /etc/nginx/sites-enabled/ignis.conf
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
