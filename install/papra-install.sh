#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/papra-hq/papra

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
  tesseract-ocr \
  tesseract-ocr-all
msg_ok "Installed Dependencies"

RELEASE=$(curl -fsSL https://api.github.com/repos/papra-hq/papra/releases | grep -oP '"tag_name":\s*"\K@papra/app@[^"]+' | head -n1)
fetch_and_deploy_gh_release "papra" "papra-hq/papra" "tarball" "${RELEASE}" "/opt/papra"

pnpm_version=$(grep -oP '"packageManager":\s*"pnpm@\K[^"]+' /opt/papra/package.json)
NODE_VERSION="24" NODE_MODULE="pnpm@$pnpm_version" setup_nodejs

msg_info "Installing Papra (Patience)"
cd /opt/papra
$STD pnpm install --frozen-lockfile
$STD pnpm --filter "@papra/app-client..." run build
$STD pnpm --filter "@papra/app-server..." run build
ln -sf /opt/papra/apps/papra-client/dist /opt/papra/apps/papra-server/public
msg_ok "Installed Papra"

msg_info "Configuring Papra"
mkdir -p /opt/papra_data/{db,documents,ingestion}
[[ ! -f /opt/papra_data/.secret ]] && openssl rand -hex 32 >/opt/papra_data/.secret
cat <<EOF >/opt/papra/apps/papra-server/.env
NODE_ENV=production
SERVER_SERVE_PUBLIC_DIR=true
PORT=1221
DATABASE_URL=file:/opt/papra_data/db/db.sqlite
DOCUMENT_STORAGE_FILESYSTEM_ROOT=/opt/papra_data/documents
PAPRA_CONFIG_DIR=/opt/papra_data
AUTH_SECRET=$(cat /opt/papra_data/.secret)
BETTER_AUTH_SECRET=$(cat /opt/papra_data/.secret)
BETTER_AUTH_TELEMETRY=0
CLIENT_BASE_URL=http://${LOCAL_IP}:1221
SERVER_BASE_URL=http://${LOCAL_IP}:1221
EMAILS_DRY_RUN=true
INGESTION_FOLDER_IS_ENABLED=true
INGESTION_FOLDER_ROOT_PATH=/opt/papra_data/ingestion
EOF
msg_ok "Configured Papra"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/papra.service
[Unit]
Description=Papra Document Management
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/papra/apps/papra-server
EnvironmentFile=/opt/papra/apps/papra-server/.env
ExecStartPre=/usr/bin/pnpm run migrate:up
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now papra
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
