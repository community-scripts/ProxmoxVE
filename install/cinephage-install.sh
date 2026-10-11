#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MoldyTaint/Cinephage

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
  python3 \
  libasound2t64 \
  libgtk-3-0t64 \
  libx11-xcb1 \
  xvfb
msg_ok "Installed Dependencies"

setup_ffmpeg
NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "cinephage" "MoldyTaint/Cinephage" "tarball"

msg_info "Building Cinephage"
cd /opt/cinephage
$STD npm ci
$STD npm run build
$STD npm prune --omit=dev
msg_ok "Built Cinephage"

msg_info "Installing Camoufox"
$STD /opt/cinephage/node_modules/.bin/camoufox-js fetch
msg_ok "Installed Camoufox"

msg_info "Configuring Cinephage"
mkdir -p /opt/cinephage_data/indexers/custom /opt/cinephage_data/external-lists/custom
cat <<EOF >/opt/cinephage_data/.env
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
APP_VERSION=$(cat ~/.cinephage)
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
DATA_DIR=/opt/cinephage_data
INDEXER_DEFINITIONS_PATH=/opt/cinephage/data/indexers/definitions
INDEXER_CUSTOM_DEFINITIONS_PATH=/opt/cinephage_data/indexers/custom
EXTERNAL_LISTS_PRESETS_PATH=/opt/cinephage/data/external-lists/presets
EXTERNAL_LISTS_CUSTOM_PRESETS_PATH=/opt/cinephage_data/external-lists/custom
CAPTCHA_ADDON_PATH=/opt/cinephage/src/lib/server/captcha/browser/addon
FFPROBE_PATH=/usr/bin/ffprobe
EOF
chmod 600 /opt/cinephage_data/.env
msg_ok "Configured Cinephage"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cinephage.service
[Unit]
Description=Cinephage
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cinephage
EnvironmentFile=/opt/cinephage_data/.env
Environment=NODE_OPTIONS=--max-old-space-size=2048
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cinephage
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
