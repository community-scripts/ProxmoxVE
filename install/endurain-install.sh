#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: johanngrobe
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/joaovitoriasilva/endurain

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="24" setup_nodejs
PG_VERSION="17" PG_MODULES="postgis" setup_postgresql
PG_DB_NAME="enduraindb" PG_DB_USER="endurain" setup_postgresql_db
import_local_ip
fetch_and_deploy_gh_release "endurain" "joaovitoriasilva/endurain" "tarball" "latest" "/opt/endurain"

msg_info "Setting up Endurain"
cd /opt/endurain
rm -rf \
  /opt/endurain/{docs,example.env,screenshot_01.png} \
  /opt/endurain/docker* \
  /opt/endurain/*.yml
mkdir -p /opt/endurain_data/{data,logs}
SECRET_KEY=$(openssl rand -hex 32)
FERNET_KEY=$(openssl rand -base64 32)
ENDURAIN_HOST=http://${LOCAL_IP}:8080
cat <<EOF >/opt/endurain/.env
DB_PASSWORD=${PG_DB_PASS}

SECRET_KEY=${SECRET_KEY}
FERNET_KEY=${FERNET_KEY}

TZ=Europe/Berlin
ENDURAIN_HOST=${ENDURAIN_HOST}
BEHIND_PROXY=false

POSTGRES_DB=${PG_DB_NAME}
POSTGRES_USER=${PG_DB_USER}
PGDATA=/var/lib/postgresql/${PG_DB_NAME}

DB_DATABASE=${PG_DB_NAME}
DB_USER=${PG_DB_USER}
DB_PORT=5432
DB_HOST=localhost

DATABASE_URL=postgresql+psycopg://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}

BACKEND_DIR="/opt/endurain/backend/app"
FRONTEND_DIR="/opt/endurain/frontend/app/dist"
DATA_DIR="/opt/endurain_data/data"
LOGS_DIR="/opt/endurain_data/logs"

#SMTP_HOST=smtp.protonmail.ch
#SMTP_PORT=587
#SMTP_USERNAME=your-email@example.com
#SMTP_PASSWORD=your-app-password
#SMTP_SECURE=true
#SMTP_SECURE_TYPE=starttls
EOF
msg_ok "Setup Endurain"

msg_info "Building Frontend"
cd /opt/endurain/frontend/app
$STD npm ci --prefer-offline
$STD npm run build
cat <<EOF >/opt/endurain/frontend/app/dist/env.js
window.env = {
  ENDURAIN_HOST: "${ENDURAIN_HOST}"
}
EOF
msg_ok "Built Frontend"

msg_info "Setting up Backend"
cd /opt/endurain/backend
$STD uv tool install poetry
$STD uv tool update-shell
export PATH="/root/.local/bin:$PATH"
$STD poetry self add poetry-plugin-export
$STD poetry export -f requirements.txt --output requirements.txt --without-hashes
$STD uv venv
$STD uv pip install -r requirements.txt
msg_ok "Setup Backend"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/endurain.service
[Unit]
Description=Endurain FastAPI Backend
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/endurain/backend/app
EnvironmentFile=/opt/endurain/.env
ExecStart=/opt/endurain/backend/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now endurain
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
