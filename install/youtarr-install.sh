#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DialmasterOrg/Youtarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  atomicparsley \
  python3
msg_ok "Installed Dependencies"

setup_ffmpeg
setup_mariadb
MARIADB_DB_NAME="youtarr" MARIADB_DB_USER="youtarr" setup_mariadb_db
NODE_VERSION="24" setup_nodejs
setup_uv

msg_info "Installing Apprise"
UV_TOOL_BIN_DIR=/usr/local/bin $STD uv tool install apprise
msg_ok "Installed Apprise"

fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp_$(arch_resolve "linux" "linux_aarch64")"
fetch_and_deploy_gh_release "youtarr" "DialmasterOrg/Youtarr" "tarball"

msg_info "Building Youtarr"
cd /opt/youtarr/client
$STD npm ci --ignore-scripts
$STD npm run build
rm -rf /opt/youtarr/client/node_modules
cd /opt/youtarr
$STD npm ci --omit=dev --ignore-scripts
msg_ok "Built Youtarr"

msg_info "Configuring Youtarr"
mkdir -p /opt/youtarr_data/config /opt/youtarr_data/videos
# config/ is hard-wired next to the app and, with DATA_PATH set, also holds images/ and jobs/ - one symlink keeps all state out of the update wipe
mv /opt/youtarr/config/config.example.json /opt/youtarr/server/
rm -rf /opt/youtarr/config
ln -sfn /opt/youtarr_data/config /opt/youtarr/config
cat <<EOF >/opt/youtarr_data/.env
PORT=3011
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=youtarr
DB_USER=youtarr
DB_PASSWORD=${MARIADB_DB_PASS}
DATA_PATH=/opt/youtarr_data/videos
EOF
chmod 600 /opt/youtarr_data/.env
msg_ok "Configured Youtarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/youtarr.service
[Unit]
Description=Youtarr
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/youtarr
EnvironmentFile=/opt/youtarr_data/.env
ExecStart=/usr/bin/node server/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now youtarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
