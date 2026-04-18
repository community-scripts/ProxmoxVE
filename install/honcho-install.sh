#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Patrick Veverka
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plastic-labs/honcho

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libpq-dev \
  build-essential
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="honcho" PG_DB_USER="honcho" PG_DB_EXTENSIONS="vector" setup_postgresql_db

fetch_and_deploy_gh_release "honcho" "plastic-labs/honcho" "tarball"

msg_info "Installing Python Dependencies"
cd /opt/honcho
$STD uv sync
msg_ok "Installed Python Dependencies"

msg_info "Configuring Honcho"
JWT_SECRET=$(openssl rand -hex 32)
WEBHOOK_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/honcho/.env
# Database
DB_CONNECTION_URI=postgresql+psycopg://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}

# Authentication (set AUTH_USE_AUTH=true and configure AUTH_JWT_SECRET to enable)
AUTH_USE_AUTH=false
AUTH_JWT_SECRET=${JWT_SECRET}

# LLM Provider — the server will not start without at least one provider configured.
# Configure at minimum: a DERIVER_PROVIDER + DERIVER_MODEL + matching API key,
# and an LLM_EMBEDDING_PROVIDER + matching API key.
#
# Example using Google (Deriver/Summary) and OpenAI (Embeddings):
# LLM_GEMINI_API_KEY=your-gemini-api-key
# LLM_OPENAI_API_KEY=your-openai-api-key
# DERIVER_PROVIDER=google
# DERIVER_MODEL=gemini-2.5-flash-lite
# LLM_EMBEDDING_PROVIDER=openai

# Cache (optional Redis)
CACHE_ENABLED=false
# CACHE_URL=redis://localhost:6379/0

# Webhooks
WEBHOOK_SECRET=${WEBHOOK_SECRET}

# Logging
LOG_LEVEL=INFO
EOF
chmod 600 /opt/honcho/.env
{
  echo "Honcho Credentials"
  echo "DB_USER: ${PG_DB_USER}"
  echo "DB_PASS: ${PG_DB_PASS}"
  echo "DB_NAME: ${PG_DB_NAME}"
  echo "JWT_SECRET: ${JWT_SECRET}"
  echo "WEBHOOK_SECRET: ${WEBHOOK_SECRET}"
} >>~/honcho.creds
msg_ok "Configured Honcho"

msg_info "Running Database Migrations"
cd /opt/honcho
$STD uv run alembic upgrade head
msg_ok "Ran Database Migrations"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/honcho-api.service
[Unit]
Description=Honcho API Server
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honcho
EnvironmentFile=/opt/honcho/.env
ExecStart=/usr/local/bin/uv run fastapi run src/main.py --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/honcho-deriver.service
[Unit]
Description=Honcho Deriver Worker
After=network.target postgresql.service honcho-api.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/honcho
EnvironmentFile=/opt/honcho/.env
ExecStart=/usr/local/bin/uv run python -m src.deriver
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now honcho-api honcho-deriver
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
