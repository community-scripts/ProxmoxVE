#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
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
$STD apt-get install -y --no-install-recommends \
  build-essential \
  aria2 \
  coreutils \
  gcc \
  g++ \
  musl-dev \
  ffmpeg \
  git \
  make \
  ca-certificates
msg_ok "Installed Dependencies"

msg_info "Setup Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv
msg_ok "Setup Python3"

NODE_VERSION="22" setup_nodejs

msg_info "Installing MeTube"
$STD git clone https://github.com/alexta69/metube /opt/metube
cd /opt/metube/ui
$STD npm install
$STD node_modules/.bin/ng build
cd /opt/metube
$STD pip3 install pipenv
$STD pipenv install
mkdir -p /opt/metube_downloads /opt/metube_downloads/.metube /opt/metube_downloads/music /opt/metube_downloads/videos
cat <<EOF >/opt/metube/.env
DOWNLOAD_DIR=/opt/metube_downloads
STATE_DIR=/opt/metube_downloads/.metube
TEMP_DIR=/opt/metube_downloads
YTDL_OPTIONS={"trim_file_name":10}
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
ExecStart=/usr/local/bin/pipenv run python3 app/main.py
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
