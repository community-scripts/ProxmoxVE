#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/storyteller-platform/storyteller

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
  git \
  pkg-config \
  libsqlite3-dev \
  sqlite3 \
  python3-setuptools \
  ffmpeg
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "readium" "readium/cli" "prebuild" "latest" "/opt/readium" "readium_linux_x86_64.tar.gz"
ln -sf /opt/readium/readium /usr/local/bin/readium
fetch_and_deploy_gl_release "storyteller" "storyteller-platform/storyteller" "tarball" "latest" "/opt/storyteller"

msg_info "Setting up Storyteller"
cd /opt/storyteller
$STD yarn install --network-timeout 600000
$STD gcc -g -fPIC -rdynamic -shared web/sqlite/uuid.c -o web/sqlite/uuid.c.so
STORYTELLER_SECRET_KEY=$(openssl rand -base64 32)
cat <<EOF >/opt/storyteller/.env
STORYTELLER_SECRET_KEY=${STORYTELLER_SECRET_KEY}
STORYTELLER_DATA_DIR=/opt/storyteller/data
PORT=8001
HOSTNAME=0.0.0.0
READIUM_PORT=9000
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
EOF
mkdir -p /opt/storyteller/data
{
  echo "Storyteller Credentials"
  echo "======================="
  echo "Secret Key: ${STORYTELLER_SECRET_KEY}"
} >~/storyteller.creds
msg_ok "Set up Storyteller"

msg_info "Building Storyteller"
cd /opt/storyteller
export CI=1
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
export SQLITE_NATIVE_BINDING=/opt/storyteller/node_modules/better-sqlite3/build/Release/better_sqlite3.node
$STD yarn workspaces foreach -Rpt --from @storyteller-platform/web --exclude @storyteller-platform/eslint run build
mkdir -p /opt/storyteller/web/.next/standalone/web/.next/static
cp -rT /opt/storyteller/web/.next/static /opt/storyteller/web/.next/standalone/web/.next/static
if [[ -d /opt/storyteller/web/public ]]; then
  mkdir -p /opt/storyteller/web/.next/standalone/web/public
  cp -rT /opt/storyteller/web/public /opt/storyteller/web/.next/standalone/web/public
fi
mkdir -p /opt/storyteller/web/.next/standalone/web/migrations
cp -rT /opt/storyteller/web/migrations /opt/storyteller/web/.next/standalone/web/migrations
mkdir -p /opt/storyteller/web/.next/standalone/web/sqlite
cp -rT /opt/storyteller/web/sqlite /opt/storyteller/web/.next/standalone/web/sqlite
ln -sf /opt/storyteller/.env /opt/storyteller/web/.next/standalone/web/.env
msg_ok "Built Storyteller"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/storyteller.service
[Unit]
Description=Storyteller
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/storyteller/web/.next/standalone/web
EnvironmentFile=/opt/storyteller/.env
ExecStart=/usr/bin/node --enable-source-maps server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now storyteller
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
