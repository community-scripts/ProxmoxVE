#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Pouzor/homelable

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nmap \
  iputils-ping \
  caddy
msg_ok "Installed Dependencies"

UV_PYTHON="3.13" setup_uv
NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_release "homelable" "Pouzor/homelable" "tarball" "latest" "/opt/homelable"

msg_info "Setting up Python Backend"
cd /opt/homelable/backend
$STD uv venv /opt/homelable/backend/.venv
$STD uv pip install --python /opt/homelable/backend/.venv/bin/python -r requirements.txt
msg_ok "Set up Python Backend"

msg_info "Configuring Homelable"
mkdir -p /opt/homelable/data
SECRET_KEY=$(openssl rand -hex 32)
BCRYPT_HASH=$(/opt/homelable/backend/.venv/bin/python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('admin'))")
cat <<EOF >/opt/homelable/backend/.env
SECRET_KEY=${SECRET_KEY}
SQLITE_PATH=/opt/homelable/data/homelab.db
CORS_ORIGINS=["http://localhost:3000","http://${LOCAL_IP}:3000"]
AUTH_USERNAME=admin
AUTH_PASSWORD_HASH='${BCRYPT_HASH}'
SCANNER_RANGES=["192.168.1.0/24"]
STATUS_CHECKER_INTERVAL=60
EOF
msg_ok "Configured Homelable"

msg_info "Building Frontend"
cd /opt/homelable/frontend
$STD npm ci
$STD npm run build
msg_ok "Built Frontend"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homelable.service
[Unit]
Description=Homelable Backend
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/homelable/backend
EnvironmentFile=/opt/homelable/backend/.env
ExecStart=/opt/homelable/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homelable
msg_ok "Created Service"

msg_info "Configuring Caddy"
cat <<EOF >/etc/caddy/Caddyfile
:3000 {
    root * /opt/homelable/frontend/dist
    file_server

    @websocket path /api/v1/status/ws/*
    handle @websocket {
        reverse_proxy 127.0.0.1:8000
    }

    handle /ws/* {
        reverse_proxy 127.0.0.1:8000
    }

    handle /api/* {
        reverse_proxy 127.0.0.1:8000
    }

    handle {
        try_files {path} {path}.html /index.html
    }
}
EOF
systemctl reload caddy
msg_ok "Configured Caddy"

motd_ssh
customize
cleanup_lxc
