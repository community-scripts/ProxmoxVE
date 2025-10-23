#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alexta69/metube

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y --no-install-recommends \
  build-essential \
  aria2 \
  coreutils \
  gcc \
  g++ \
  musl-dev \
  ffmpeg \
  make \
  ca-certificates
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="22" setup_nodejs

msg_info "Installing Deno"
export DENO_INSTALL="/usr/local"
curl -fsSL https://deno.land/install.sh | $STD sh -s -- -y
[[ ":$PATH:" != *":/usr/local/bin:"* ]] &&
  echo -e "\nexport PATH=\"/usr/local/bin:\$PATH\"" >>~/.bashrc &&
  source ~/.bashrc
msg_ok "Installed Deno"

fetch_and_deploy_gh_release "metube" "alexta69/metube" "tarball" "latest"

msg_info "Installing MeTube"
cd /opt/metube/ui
$STD npm install
$STD node_modules/.bin/ng build
cd /opt/metube
$STD uv sync

mkdir -p /opt/metube_downloads /opt/metube_downloads/.metube /opt/metube_downloads/music /opt/metube_downloads/videos
cat <<EOF >/opt/metube/.env
DOWNLOAD_DIR=/opt/metube_downloads
STATE_DIR=/opt/metube_downloads/.metube
TEMP_DIR=/opt/metube_downloads
YTDL_OPTIONS={"trim_file_name":10,"extractor_args":{"youtube":{"player_client":["default","-tv_simply"]}}}
EOF
msg_ok "Installed MeTube"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/metube.service
[Unit]
Description=Metube - YouTube Downloader
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/metube
EnvironmentFile=/opt/metube/.env
ExecStart=/opt/metube/.venv/bin/python3 app/main.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now metube
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
