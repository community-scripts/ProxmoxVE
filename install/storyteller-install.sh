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
  cmake \
  sqlite3 \
  libsqlite3-dev \
  argon2 \
  ffmpeg \
  libcurl4t64 \
  libxml2
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

fetch_and_deploy_gh_release "readium" "readium/cli" "prebuild" "v0.9.1" "/opt/readium" "readium_linux_$(arch_resolve "x86_64" "arm64").tar.gz"
ln -sf /opt/readium/readium /usr/local/bin/readium
fetch_and_deploy_gl_release "storyteller" "storyteller-platform/storyteller" "tarball" "latest" "/opt/storyteller" "" "web-v2"

msg_info "Building Storyteller (Patience)"
cd /opt/storyteller
$STD corepack yarn install
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
export SQLITE_NATIVE_BINDING=/opt/storyteller/node_modules/better-sqlite3/build/Release/better_sqlite3.node
$STD corepack yarn workspaces foreach -Rpt --from @storyteller-platform/web --exclude @storyteller-platform/eslint run build
STANDALONE=/opt/storyteller/applications/web/.next/standalone
WEB_DIR="$STANDALONE/applications/web"
mkdir -p "$WEB_DIR"/{public,.next/static,.next/cache,migrations,sqlite,scripts}
cp -rT applications/web/public "$WEB_DIR/public"
cp -rT applications/web/.next/static "$WEB_DIR/.next/static"
cp -rT applications/web/migrations "$WEB_DIR/migrations"
cp applications/web/sqlite/uuid.c.so "$WEB_DIR/sqlite/"
cp docker-scripts/reset-password.sh "$WEB_DIR/scripts/"
cp -r applications/web/work-dist applications/web/file-write-dist "$WEB_DIR/"
mkdir -p "$WEB_DIR/work-dist/@storyteller-platform/align/prebuilds"
cp -r "libraries/align/prebuilds/linux-$(arch_resolve "x64" "arm64")" "$WEB_DIR/work-dist/@storyteller-platform/align/prebuilds/"
cp node_modules/@echogarden/icu-segmentation-wasm/wasm/*.wasm "$WEB_DIR/work-dist/"
cp -rT node_modules/@parcel "$STANDALONE/node_modules/@parcel"
cp -rT node_modules/kuromoji "$STANDALONE/node_modules/kuromoji"
msg_ok "Built Storyteller"

msg_info "Installing Whisper"
WHISPER_VARIANT="linux-$(arch_resolve "x64" "arm64")-cpu"
$STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install binary "$WHISPER_VARIANT"
$STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install model tiny.en
if [[ "$WHISPER_VARIANT" == "linux-x64-cpu" ]]; then
  $STD node /opt/storyteller/libraries/ghost-story/dist/cli/bin.js install binary linux-x64-cpu-legacy
fi
msg_ok "Installed Whisper"

msg_info "Configuring Storyteller"
mkdir -p /opt/storyteller/data
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
chmod 600 /opt/storyteller/.env
ln -sf /opt/storyteller/.env "$WEB_DIR/.env"
cat <<EOF >~/storyteller.creds
Storyteller Credentials
=======================
Secret Key: ${STORYTELLER_SECRET_KEY}
EOF
msg_ok "Configured Storyteller"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/storyteller.service
[Unit]
Description=Storyteller
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEB_DIR}
EnvironmentFile=/opt/storyteller/.env
Environment=SQLITE_NATIVE_BINDING=${STANDALONE}/node_modules/better-sqlite3/build/Release/better_sqlite3.node
Environment=ERROR_ALIGN_NATIVE_BINDING=${WEB_DIR}/work-dist/@storyteller-platform/align/
Environment=STORYTELLER_WORKER=worker.mjs
Environment=STORYTELLER_FILE_WRITE_WORKER=fileWriteWorker.mjs
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
