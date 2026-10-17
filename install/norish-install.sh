#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/norish-recipes/norish

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="norish" PG_DB_USER="norish" setup_postgresql_db
PYTHON_VERSION="3.14" setup_uv

fetch_and_deploy_gh_release "norish" "norish-recipes/norish" "tarball"
NODE_VERSION="22" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/norish/package.json)" setup_nodejs
fetch_and_deploy_gh_release "obscura" "h4ckf0r0day/obscura" "prebuild" "v$(sed -n 's/^OBSCURA_VERSION=//p' /opt/norish/docker/obscura/pin.env)" "/opt/obscura" "obscura-$(arch_resolve "x86_64" "aarch64")-linux-stealth.tar.gz"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "$(arch_resolve "yt-dlp_linux" "yt-dlp_linux_aarch64")"

msg_info "Building Norish"
cd /opt/norish
$STD pnpm install --frozen-lockfile --filter "@norish/web..." --filter norish
$STD uv sync --project /opt/norish/apps/parser-api --locked
NODE_ENV=production SKIP_ENV_VALIDATION=1 NEXT_TELEMETRY_DISABLED=1 $STD pnpm turbo run build --filter "@norish/web"
rm -rf /opt/norish/apps/web/.next/cache /opt/norish/apps/web/.next/standalone
msg_ok "Built Norish"

msg_info "Configuring Norish"
mkdir -p /opt/norish_data/uploads
cat <<EOF >/opt/norish_data/.env
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
AUTH_URL=http://${LOCAL_IP}:3000
DATABASE_URL=postgresql://norish:${PG_DB_PASS}@localhost:5432/norish
MASTER_KEY=$(openssl rand -base64 32)
REDIS_URL=redis://127.0.0.1:6379
OBSCURA_ENDPOINT=ws://127.0.0.1:9222
UPLOADS_DIR=/opt/norish_data/uploads
YT_DLP_BIN_DIR=/usr/local/bin
EOF
chmod 600 /opt/norish_data/.env
msg_ok "Configured Norish"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/obscura.service
[Unit]
Description=Obscura headless browser for Norish URL imports
After=network.target

[Service]
Type=simple
ExecStart=/opt/obscura/obscura serve --host 127.0.0.1 --port 9222 --stealth
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/norish.service
[Unit]
Description=Norish
After=network.target postgresql.service redis-server.service obscura.service
Requires=postgresql.service redis-server.service
Wants=obscura.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/norish
EnvironmentFile=/opt/norish_data/.env
ExecStart=/usr/bin/node /opt/norish/dist-server/index.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now obscura norish
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
