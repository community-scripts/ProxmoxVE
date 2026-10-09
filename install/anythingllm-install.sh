#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Mintplex-Labs/anything-llm

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
  python3-dev \
  libgomp1 \
  git \
  chromium
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "anythingllm" "Mintplex-Labs/anything-llm" "tarball"

msg_info "Configuring AnythingLLM"
mkdir -p /opt/anythingllm_data/storage
cp -RTn /opt/anythingllm/server/storage /opt/anythingllm_data/storage 2>/dev/null || true
rm -rf /opt/anythingllm/server/storage
ln -sfn /opt/anythingllm_data/storage /opt/anythingllm/server/storage
cat <<EOF >/opt/anythingllm/server/.env
SERVER_PORT=3001
STORAGE_DIR="/opt/anythingllm/server/storage"
JWT_SECRET="$(openssl rand -hex 32)"
SIG_KEY="$(openssl rand -hex 32)"
SIG_SALT="$(openssl rand -hex 32)"
VECTOR_DB="lancedb"
EOF
cat <<EOF >/opt/anythingllm/collector/.env
STORAGE_DIR="/opt/anythingllm/server/storage"
EOF
cat <<EOF >/opt/anythingllm/frontend/.env
VITE_API_BASE='/api'
EOF
msg_ok "Configured AnythingLLM"

msg_info "Building AnythingLLM (Patience)"
cd /opt/anythingllm
export PUPPETEER_SKIP_DOWNLOAD=true
export NODE_OPTIONS="--max-old-space-size=3072"
$STD yarn setup
cd /opt/anythingllm/frontend
$STD yarn build
cp -R /opt/anythingllm/frontend/dist /opt/anythingllm/server/public
cd /opt/anythingllm/server
$STD npx prisma generate --schema=./prisma/schema.prisma
$STD npx prisma migrate deploy --schema=./prisma/schema.prisma
msg_ok "Built AnythingLLM"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/anythingllm.service
[Unit]
Description=AnythingLLM Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anythingllm/server
Environment=NODE_ENV=production
ExecStart=/usr/bin/node index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/anythingllm-collector.service
[Unit]
Description=AnythingLLM Collector
Wants=network-online.target
After=network-online.target anythingllm.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anythingllm/collector
Environment=NODE_ENV=production
Environment=PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ExecStart=/usr/bin/node index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now anythingllm anythingllm-collector
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
