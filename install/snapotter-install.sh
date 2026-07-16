#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snapotter.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  imagemagick \
  ghostscript \
  potrace \
  libopenjp2-tools \
  libegl1 \
  libgl1 \
  libglib2.0-0 \
  libsm6 \
  libxext6 \
  libxrender1 \
  libwayland-client0 \
  libwayland-cursor0 \
  libwayland-egl1 \
  libxkbcommon0 \
  libxkbcommon-x11-0 \
  libxcursor1 \
  python3 \
  python3-dev \
  gcc \
  g++
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.11" setup_uv
NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" setup_postgresql

msg_info "Waiting for PostgreSQL"
PG_READY=0
for _ in {1..30}; do
  if pg_isready -q -h 127.0.0.1 -p 5432; then
    PG_READY=1
    break
  fi
  sleep 1
done
if [[ "$PG_READY" -ne 1 ]]; then
  msg_error "PostgreSQL is not accepting connections on 127.0.0.1:5432 after 30s"
  exit 1
fi
msg_ok "PostgreSQL is ready"

PG_DB_NAME="snapotter" PG_DB_USER="snapotter" setup_postgresql_db

msg_info "Installing Redis"
$STD apt install -y redis-server
if grep -q '^appendonly ' /etc/redis/redis.conf; then
  sed -i 's/^appendonly .*/appendonly yes/' /etc/redis/redis.conf
else
  echo 'appendonly yes' >>/etc/redis/redis.conf
fi
$STD systemctl enable --now redis-server
msg_ok "Installed Redis"

fetch_and_deploy_gh_release "caire" "esimov/caire" "prebuild" "latest" "/usr/local/bin" "caire-*-linux-amd64.tar.gz"
fetch_and_deploy_gh_release "snapotter" "snapotter-hq/SnapOtter" "prebuild" "latest" "/opt/snapotter" "snapotter-*-linux-amd64.tar.gz"

msg_info "Setting up Python Environment"
mkdir -p /opt/snapotter_data/ai/models/rembg
$STD uv python install 3.11
$STD uv venv --seed --python 3.11 /opt/snapotter_data/ai/venv
#if [[ -f /opt/snapotter/packages/ai/python/requirements.txt ]]; then
#  $STD uv pip install \
#    --python /opt/snapotter_data/ai/venv/bin/python \
#    -r /opt/snapotter/packages/ai/python/requirements.txt
#fi
ln -sfn /opt/snapotter /app
msg_ok "Set up Python Environment"

msg_info "Configuring SnapOtter"
mkdir -p /opt/snapotter_data/files
mkdir -p /tmp/snapotter-workspace

cat <<EOF >/opt/snapotter_data/.env
PORT=1349
NODE_ENV=production
DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
REDIS_URL=redis://127.0.0.1:6379
WORKSPACE_PATH=/tmp/snapotter-workspace
FILES_STORAGE_PATH=/opt/snapotter_data/files
PYTHON_VENV_PATH=/opt/snapotter_data/ai/venv
MODELS_PATH=/opt/snapotter_data/ai/models
DATA_DIR=/opt/snapotter_data
FEATURE_MANIFEST_PATH=/opt/snapotter/docker/feature-manifest.json
U2NET_HOME=/opt/snapotter_data/ai/models/rembg
AUTH_ENABLED=true
DEFAULT_USERNAME=admin
DEFAULT_PASSWORD=admin
LOG_LEVEL=info
TRUST_PROXY=true
FILE_MAX_AGE_HOURS=72
CLEANUP_INTERVAL_MINUTES=60
ANALYTICS_ENABLED=false
EOF
msg_ok "Configured SnapOtter"

msg_info "Creating Service"
PNPM_BIN="$(command -v pnpm)"
cat <<EOF >/etc/systemd/system/snapotter.service
[Unit]
Description=SnapOtter Service
Wants=network-online.target
After=network-online.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/snapotter
EnvironmentFile=/opt/snapotter_data/.env
ExecStart=${PNPM_BIN} --filter @snapotter/api run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now snapotter
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
