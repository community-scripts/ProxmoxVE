#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz) & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://karakeep.app/

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
  ca-certificates \
  chromium \
  graphicsmagick \
  ghostscript
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "monolith" "Y2Z/monolith" "singlefile" "latest" "/usr/bin" "monolith-gnu-linux-x86_64"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp-nightly-builds" "singlefile" "latest" "/usr/bin" "yt-dlp_linux"
fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary"

msg_info "Configuring Meilisearch"
curl -fsSL "https://raw.githubusercontent.com/meilisearch/meilisearch/latest/config.toml" -o "/etc/meilisearch.toml"
MASTER_KEY=$(openssl rand -base64 12)
sed -i \
  -e 's|^env =.*|env = "production"|' \
  -e "s|^# master_key =.*|master_key = \"$MASTER_KEY\"|" \
  -e 's|^db_path =.*|db_path = "/var/lib/meilisearch/data"|' \
  -e 's|^dump_dir =.*|dump_dir = "/var/lib/meilisearch/dumps"|' \
  -e 's|^snapshot_dir =.*|snapshot_dir = "/var/lib/meilisearch/snapshots"|' \
  -e 's|^# no_analytics = true|no_analytics = true|' \
  /etc/meilisearch.toml
msg_ok "Configured Meilisearch"

fetch_and_deploy_gh_release "karakeep" "karakeep-app/karakeep"
cd /opt/karakeep
MODULE_VERSION="$(jq -r '.packageManager | split("@")[1]' /opt/karakeep/package.json)"
NODE_VERSION="22" NODE_MODULE="pnpm@${MODULE_VERSION}" setup_nodejs

msg_info "Installing karakeep"
export PUPPETEER_SKIP_DOWNLOAD="true"
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD="true"
export NEXT_TELEMETRY_DISABLED=1
export CI="true"
cd /opt/karakeep/apps/web
$STD pnpm install --frozen-lockfile
$STD pnpm build
cd /opt/karakeep/apps/workers
$STD pnpm install --frozen-lockfile
$STD pnpm build
cd /opt/karakeep/apps/cli
$STD pnpm install --frozen-lockfile
$STD pnpm build
$STD pnpm store prune

export DATA_DIR=/opt/karakeep_data
karakeep_SECRET=$(openssl rand -base64 36 | cut -c1-24)
mkdir -p /etc/karakeep
cat <<EOF >/etc/karakeep/karakeep.env
SERVER_VERSION="$(sed 's/^v//' ~/.karakeep)"
NEXTAUTH_SECRET="$karakeep_SECRET"
NEXTAUTH_URL="http://localhost:3000"
DATA_DIR=${DATA_DIR}
MEILI_ADDR="http://127.0.0.1:7700"
MEILI_MASTER_KEY="$MASTER_KEY"
BROWSER_WEB_URL="http://127.0.0.1:9222"
DB_WAL_MODE=true

# If you're planning to use OpenAI for tagging. Uncomment the following line:
# OPENAI_API_KEY="<API_KEY>"

# If you're planning to use ollama for tagging, uncomment the following lines:
# OLLAMA_BASE_URL="<OLLAMA_ADDR>"
# OLLAMA_KEEP_ALIVE="5m"

# You can change the models used by uncommenting the following lines, and changing them according to your needs:
# INFERENCE_TEXT_MODEL="gpt-4o-mini"
# INFERENCE_IMAGE_MODEL="gpt-4o-mini" 

# Additional inference defaults
# INFERENCE_CONTEXT_LENGTH="2048"
# INFERENCE_ENABLE_AUTO_TAGGING=true
# INFERENCE_ENABLE_AUTO_SUMMARIZATION=false

# Crawler defaults
# CRAWLER_NUM_WORKERS="1"
# CRAWLER_DOWNLOAD_BANNER_IMAGE=true
# CRAWLER_STORE_SCREENSHOT=true
# CRAWLER_FULL_PAGE_SCREENSHOT=false
# CRAWLER_FULL_PAGE_ARCHIVE=false
# CRAWLER_VIDEO_DOWNLOAD=false
# CRAWLER_VIDEO_DOWNLOAD_MAX_SIZE="50"
# CRAWLER_ENABLE_ADBLOCKER=true
EOF
msg_ok "Installed karakeep"

msg_info "Running Database Migration"
mkdir -p ${DATA_DIR}
cd /opt/karakeep/packages/db
$STD pnpm migrate
msg_ok "Database Migration Completed"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=Meilisearch
After=network.target

[Service]
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/karakeep-web.service
[Unit]
Description=karakeep Web
Wants=network.target karakeep-workers.service
After=network.target karakeep-workers.service

[Service]
ExecStart=pnpm start
WorkingDirectory=/opt/karakeep/apps/web
EnvironmentFile=/etc/karakeep/karakeep.env
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/karakeep-browser.service
[Unit]
Description=karakeep Headless Browser
After=network.target

[Service]
User=root
ExecStart=/usr/bin/chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --hide-scrollbars
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/karakeep-workers.service
[Unit]
Description=karakeep Workers
Wants=network.target karakeep-browser.service meilisearch.service
After=network.target karakeep-browser.service meilisearch.service

[Service]
ExecStart=/usr/bin/node dist/index.js
WorkingDirectory=/opt/karakeep/apps/workers
EnvironmentFile=/etc/karakeep/karakeep.env
Restart=always
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now meilisearch karakeep-browser karakeep-workers karakeep-web
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
