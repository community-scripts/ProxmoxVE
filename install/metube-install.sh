#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y \
  build-essential \
  aria2 \
  coreutils \
  musl-dev \
  ffmpeg
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

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
if command -v corepack >/dev/null 2>&1; then
  $STD corepack enable
  $STD corepack prepare pnpm --activate || true
fi
$STD pnpm install --frozen-lockfile
$STD pnpm run build
cd /opt/metube
$STD uv sync
mkdir -p /opt/metube_downloads /opt/metube_downloads/.metube /opt/metube_downloads/music /opt/metube_downloads/videos
cat <<EOF >/opt/metube/.env
# Storage & Directories
DOWNLOAD_DIR=/opt/metube_downloads
AUDIO_DOWNLOAD_DIR=/opt/metube_downloads/music
STATE_DIR=/opt/metube_downloads/.metube
TEMP_DIR=/opt/metube_downloads

# Download Behavior
DOWNLOAD_MODE=limited
MAX_CONCURRENT_DOWNLOADS=3
DELETE_FILE_ON_TRASHCAN=false
DEFAULT_OPTION_PLAYLIST_STRICT_MODE=false
DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT=0

# File Naming & yt-dlp
OUTPUT_TEMPLATE=%(title)s.%(ext)s
OUTPUT_TEMPLATE_CHAPTER=%(title)s - %(section_number)s %(section_title)s.%(ext)s
OUTPUT_TEMPLATE_PLAYLIST=%(playlist_title)s/%(title)s.%(ext)s
YTDL_OPTIONS={"trim_file_name":200,"extractor_args":{"youtube":{"player_client":["default","-tv_simply"]}}}

# Custom Directories
CUSTOM_DIRS=true
CREATE_CUSTOM_DIRS=true

# Basic Setup
DEFAULT_THEME=auto
LOGLEVEL=INFO
ENABLE_ACCESSLOG=false
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
cleanup_lxc
