#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Gentleman-Programming/engram

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

PG_VERSION="16" setup_postgresql
PG_DB_NAME="engram" PG_DB_USER="engram" setup_postgresql_db

fetch_and_deploy_gh_release "engram" "Gentleman-Programming/engram" "prebuild" "latest" "/opt/engram" "engram_*_linux_$(arch_resolve).tar.gz"

msg_info "Configuring Engram Cloud"
ln -sf /opt/engram/engram /usr/local/bin/engram
mkdir -p /opt/engram_data
cat <<EOF >/opt/engram_data/.env
ENGRAM_DATABASE_URL=postgres://engram:${PG_DB_PASS}@127.0.0.1:5432/engram?sslmode=disable
ENGRAM_CLOUD_HOST=127.0.0.1
ENGRAM_PORT=18080
ENGRAM_CLOUD_TOKEN=${var_cloud_token:-$(random_password 48)}
ENGRAM_CLOUD_ADMIN=${var_admin_token:-$(random_password 48)}
ENGRAM_JWT_SECRET=$(random_password 64)
ENGRAM_CLOUD_TOKEN_PEPPER=$(random_password 64)
ENGRAM_CLOUD_ALLOWED_PROJECTS=${var_allowed_projects:-*}
EOF
chmod 600 /opt/engram_data/.env
msg_ok "Configured Engram Cloud"

create_self_signed_cert "engram"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/engram
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name _;
    client_max_body_size 32m;

    ssl_certificate /etc/ssl/engram/engram.crt;
    ssl_certificate_key /etc/ssl/engram/engram.key;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
    }
}
EOF
nginx_enable_site "engram"
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/engram.service
[Unit]
Description=Engram Cloud
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/engram_data
EnvironmentFile=/opt/engram_data/.env
ExecStart=/opt/engram/engram cloud serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now engram
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
