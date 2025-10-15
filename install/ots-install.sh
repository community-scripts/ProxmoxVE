#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Luzifer/ots

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    redis-server \
    nginx \
    openssl
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "ots" "Luzifer/ots" "prebuild" "latest" "/opt/ots" "ots_linux_amd64.tgz"

msg_info "Setup OTS"
cat <<EOF >/opt/ots/.env
LISTEN=127.0.0.1:3000
REDIS_URL=redis://127.0.0.1:6379
SECRET_EXPIRY=604800
STORAGE_TYPE=redis
EOF
msg_ok "Setup OTS"

msg_info "Generating Universal SSL Certificate"
mkdir -p /etc/ssl/ots
$STD openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/ssl/ots/key.pem \
    -out /etc/ssl/ots/cert.pem \
    -subj "/CN=ots"
msg_ok "Certificate Generated"

msg_info "Setting up nginx"
cat <<EOF >/etc/nginx/sites-available/ots.conf
server {
    listen 80;
    listen [::]:80;
    server_name ots;
    return 301 https://\$host\$request_uri;
}
server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name ots;

  ssl_certificate /etc/ssl/ots/cert.pem;
  ssl_certificate_key /etc/ssl/ots/key.pem;

  location / {
    add_header X-Robots-Tag noindex;

    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    client_max_body_size 64M;
    proxy_pass http://127.0.0.1:3000/;
  }
}
EOF

ln -s /etc/nginx/sites-available/ots.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/ots.service
[Unit]
Description=One-Time-Secret Service
After=network-online.target
Requires=network-online.target

[Service]
EnvironmentFile=/opt/ots/.env
ExecStart=/opt/ots/ots
Restart=Always
RestartSecs=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ots
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
