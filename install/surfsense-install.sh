#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MODSetter/SurfSense

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libgomp1 \
  libxinerama1 \
  libx11-xcb1 \
  libxext6 \
  libsm6 \
  libfontconfig1 \
  fonts-dejavu-core \
  libnss3 \
  libdbus-1-3 \
  libcairo2 \
  libglib2.0-0t64 \
  libcups2t64
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "surfsense" "MODSetter/SurfSense" "tarball"
fetch_and_deploy_gh_release "caddy" "caddyserver/caddy" "prebuild" "v$(grep -oP 'CADDY_IMAGE=caddy:\K[0-9.]+' /opt/surfsense/docker/surfsense/Dockerfile)" "/opt/caddy" "caddy_*_linux_$(arch_resolve).tar.gz"
NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/surfsense/surfsense_local/frontend/package.json)" setup_nodejs
PYTHON_VERSION="3.12" setup_uv

msg_info "Building SurfSense Frontend"
cd /opt/surfsense/surfsense_local/frontend
$STD pnpm install --frozen-lockfile
VITE_API_BASE=/api VITE_SURFSENSE_RUNTIME=docker VITE_SURFSENSE_VERSION="$(cat ../VERSION)" $STD pnpm build
rm -rf node_modules
msg_ok "Built SurfSense Frontend"

msg_info "Setting up SurfSense Backend"
cd /opt/surfsense/surfsense_local/backend
$STD uv sync --frozen --no-dev
SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_embedding_model.py models
SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_docling_models.py models
SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_silero_vad.py models
msg_ok "Set up SurfSense Backend"

msg_info "Staging llama.cpp and opencode"
cd /opt/surfsense/surfsense_local
$STD node runtimes/fetch-llamacpp.mjs --variant cpu --out electron/llamacpp
$STD node runtimes/opencode/stage.mjs
msg_ok "Staged llama.cpp and opencode"

msg_info "Configuring SurfSense"
mkdir -p /opt/surfsense_data
cat <<EOF >/opt/surfsense_data/.env
SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data
SURFSENSE_LOCAL_CADDY=/opt/caddy/caddy
SURFSENSE_LOCAL_CADDYFILE=/opt/surfsense/docker/surfsense/caddy/Caddyfile
SURFSENSE_LOCAL_PUBLIC_PORT=80
SURFSENSE_LOCAL_CORS_ORIGINS=
SURFSENSE_PASSWORD=${var_surfsense_password:-}
SURFSENSE_ALLOWED_HOSTS=
SURFSENSE_AUTH=
SURFSENSE_TLS=
SURFSENSE_DOMAIN=
SURFSENSE_HTTPS_PORT=443
EOF
chmod 600 /opt/surfsense_data/.env
msg_ok "Configured SurfSense"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/surfsense.service
[Unit]
Description=SurfSense
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/surfsense/surfsense_local
EnvironmentFile=/opt/surfsense_data/.env
ExecStart=/usr/bin/node /opt/surfsense/surfsense_local/headless/main.ts
KillMode=mixed
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now surfsense
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
