#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz) & vhsdream
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  g++ \
  build-essential \
  curl \
  git \
  sudo \
  gnupg \
  ca-certificates \
  chromium/stable \
  chromium-common/stable \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Additional Tools"
wget -q https://github.com/Y2Z/monolith/releases/latest/download/monolith-gnu-linux-x86_64 -O /usr/bin/monolith
chmod +x /usr/bin/monolith
wget -q https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux -O /usr/bin/yt-dlp
chmod +x /usr/bin/yt-dlp
msg_ok "Installed Additional Tools"

msg_info "Installing Meilisearch"
cd /tmp
wget -q https://github.com/meilisearch/meilisearch/releases/latest/download/meilisearch.deb
$STD dpkg -i meilisearch.deb
wget -q https://raw.githubusercontent.com/meilisearch/meilisearch/latest/config.toml -O /etc/meilisearch.toml
MASTER_KEY=$(openssl rand -base64 12)
sed -i \
    -e 's|^env =.*|env = "production"|' \
    -e "s|^# master_key =.*|master_key = \"$MASTER_KEY\"|" \
    -e 's|^db_path =.*|db_path = "/var/lib/meilisearch/data"|' \
    -e 's|^dump_dir =.*|dump_dir = "/var/lib/meilisearch/dumps"|' \
    -e 's|^snapshot_dir =.*|snapshot_dir = "/var/lib/meilisearch/snapshots"|' \
    -e 's|^# no_analytics = true|no_analytics = true|' \
    /etc/meilisearch.toml
msg_ok "Installed Meilisearch"

msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing Hoarder"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/hoarder-app/hoarder/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/hoarder-app/hoarder/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv hoarder-${RELEASE} /opt/hoarder
cd /opt/hoarder
corepack enable
export PUPPETEER_SKIP_DOWNLOAD="true"
export NEXT_TELEMETRY_DISABLED=1
export CI="true"
cd /opt/hoarder/apps/web
$STD pnpm install --frozen-lockfile
$STD pnpm exec next build --experimental-build-mode compile
cp -r /opt/hoarder/apps/web/.next/standalone/apps/web/server.js /opt/hoarder/apps/web
cd /opt/hoarder/apps/workers
$STD pnpm install --frozen-lockfile

export DATA_DIR=/opt/hoarder_data
HOARDER_SECRET=$(openssl rand -base64 36 | cut -c1-24)
cat <<EOF >/opt/hoarder/.env
SERVER_VERSION=$RELEASE
NEXTAUTH_SECRET="$HOARDER_SECRET"
NEXTAUTH_URL="http://localhost:3000"
DATA_DIR="$DATA_DIR"
MEILI_ADDR="http://127.0.0.1:7700"
MEILI_MASTER_KEY="$MASTER_KEY"
BROWSER_WEB_URL="http://127.0.0.1:9222"

# If you're planning to use OpenAI for tagging. Uncomment the following line:
# OPENAI_API_KEY="<API_KEY>"

# If you're planning to use ollama for tagging, uncomment the following lines:
# OLLAMA_BASE_URL="<OLLAMA_ADDR>"

# You can change the models used by uncommenting the following lines, and changing them according to your needs:
# INFERENCE_TEXT_MODEL="gpt-4o-mini"
# INFERENCE_IMAGE_MODEL="gpt-4o-mini" 
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Hoarder"

msg_info "Running Database Migration"
mkdir -p ${DATA_DIR}
cd /opt/hoarder/packages/db
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

cat <<EOF >/etc/systemd/system/hoarder-web.service
[Unit]
Description=Hoarder Web
Wants=network.target hoarder-workers.service
After=network.target hoarder-workers.service

[Service]
ExecStart=pnpm start
WorkingDirectory=/opt/hoarder/apps/web
EnvironmentFile=/opt/hoarder/.env
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/hoarder-browser.service
[Unit]
Description=Hoarder Headless Browser
After=network.target

[Service]
User=root
ExecStart=/usr/bin/chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --hide-scrollbars
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/hoarder-workers.service
[Unit]
Description=Hoarder Workers
Wants=network.target hoarder-browser.service meilisearch.service
After=network.target hoarder-browser.service meilisearch.service

[Service]
ExecStart=pnpm start:prod
WorkingDirectory=/opt/hoarder/apps/workers
EnvironmentFile=/opt/hoarder/.env
Restart=always
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl -q enable --now meilisearch.service hoarder-browser.service hoarder-workers.service hoarder-web.service
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/meilisearch.deb
rm -f /opt/v${RELEASE}.zip
$STD apt-get autoremove -y
$STD apt-get autoclean -y
msg_ok "Cleaned"
