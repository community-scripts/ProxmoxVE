#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lklynet/aurral

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
  ffmpeg \
  fontconfig \
  fonts-dejavu-core
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp"
fetch_and_deploy_gh_release "aurral" "lklynet/aurral" "tarball"

msg_info "Building Aurral"
cd /opt/aurral
export VITE_APP_VERSION="$(cat ~/.aurral)"
export VITE_GITHUB_REPO="lklynet/aurral"
export VITE_RELEASE_CHANNEL="stable"
$STD npm ci --workspace frontend --include-workspace-root=false
$STD npm run build --workspace frontend
$STD npm ci --workspace backend --omit=dev --include=optional --include-workspace-root=false
msg_ok "Built Aurral"

msg_info "Creating Service"
mkdir -p /opt/aurral_data
cat <<EOF >/opt/aurral/aurral.env
NODE_ENV=production
PORT=3001
AURRAL_DATA_DIR=/opt/aurral_data
APP_VERSION=$(cat ~/.aurral)
EOF
cat <<EOF >/etc/systemd/system/aurral.service
[Unit]
Description=Aurral Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/aurral
EnvironmentFile=/opt/aurral/aurral.env
ExecStart=/usr/bin/node backend/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now aurral
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
