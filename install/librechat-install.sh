#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danny-avila/LibreChat

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

MONGO_VERSION="8.0" setup_mongodb
setup_meilisearch
PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="ragapi" PG_DB_USER="ragapi" PG_DB_EXTENSIONS="vector" setup_postgresql_db
NODE_VERSION="24" setup_nodejs
UV_PYTHON="3.12" setup_uv

fetch_and_deploy_gh_tag "librechat" "danny-avila/LibreChat"
fetch_and_deploy_gh_release "rag-api" "danny-avila/rag_api" "tarball"

msg_info "Installing LibreChat Dependencies"
cd /opt/librechat
$STD npm ci
msg_ok "Installed LibreChat Dependencies"

msg_info "Building Frontend"
$STD npm run frontend
$STD npm prune --production
$STD npm cache clean --force
msg_ok "Built Frontend"

msg_info "Installing RAG API Dependencies"
cd /opt/rag-api
$STD uv venv --python 3.12 --seed .venv
$STD .venv/bin/pip install -r requirements.lite.txt
mkdir -p /opt/rag-api/uploads
msg_ok "Installed RAG API Dependencies"

msg_info "Configuring LibreChat"
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
CREDS_KEY=$(openssl rand -hex 32)
CREDS_IV=$(openssl rand -hex 16)
cat <<EOF >/opt/librechat/.env
HOST=0.0.0.0
PORT=3080
MONGO_URI=mongodb://127.0.0.1:27017/LibreChat
DOMAIN_CLIENT=http://${LOCAL_IP}:3080
DOMAIN_SERVER=http://${LOCAL_IP}:3080
NO_INDEX=true
TRUST_PROXY=1
JWT_SECRET=${JWT_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
SESSION_EXPIRY=1000 * 60 * 15
REFRESH_TOKEN_EXPIRY=(1000 * 60 * 60 * 24) * 7
CREDS_KEY=${CREDS_KEY}
CREDS_IV=${CREDS_IV}
ALLOW_EMAIL_LOGIN=true
ALLOW_REGISTRATION=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_SOCIAL_REGISTRATION=false
ALLOW_PASSWORD_RESET=false
ALLOW_UNVERIFIED_EMAIL_LOGIN=true
SEARCH=true
MEILI_NO_ANALYTICS=true
MEILI_HOST=http://127.0.0.1:7700
MEILI_MASTER_KEY=${MEILISEARCH_MASTER_KEY}
RAG_PORT=8000
RAG_API_URL=http://127.0.0.1:8000
APP_TITLE=LibreChat
ENDPOINTS=openAI,agents,assistants,anthropic,google
# OPENAI_API_KEY=your-key-here
# OPENAI_MODELS=
# ANTHROPIC_API_KEY=your-key-here
# GOOGLE_KEY=your-key-here
EOF
msg_ok "Configured LibreChat"

msg_info "Configuring RAG API"
cat <<EOF >/opt/rag-api/.env
VECTOR_DB_TYPE=pgvector
DB_HOST=127.0.0.1
DB_PORT=5432
POSTGRES_DB=${PG_DB_NAME}
POSTGRES_USER=${PG_DB_USER}
POSTGRES_PASSWORD=${PG_DB_PASS} 
RAG_HOST=0.0.0.0
RAG_PORT=8000
JWT_SECRET=${JWT_SECRET}
RAG_UPLOAD_DIR=/opt/rag-api/uploads/
EOF
msg_ok "Configured RAG API"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/librechat.service
[Unit]
Description=LibreChat
After=network.target mongod.service meilisearch.service rag-api.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/librechat
EnvironmentFile=/opt/librechat/.env
ExecStart=/usr/bin/npm run backend
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/rag-api.service
[Unit]
Description=LibreChat RAG API
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rag-api
EnvironmentFile=/opt/rag-api/.env
ExecStart=/opt/rag-api/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rag-api librechat
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
