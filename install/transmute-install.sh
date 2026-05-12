#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/transmute-app/transmute

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

UV_PYTHON="3.13" setup_uv
NODE_VERSION="25" setup_nodejs
setup_ffmpeg
setup_gs

msg_info "Installing Dependencies"
$STD apt install -y \
  inkscape \
  tesseract-ocr \
  libreoffice-impress \
  libreoffice-common \
  libmagic1 \
  xvfb \
  libsm6 \
  libxext6 \
  libpango-1.0-0 \
  libopengl0 \
  libpangocairo-1.0-0 \
  libgdk-pixbuf-2.0-0 \
  libffi-dev \
  libcairo2 \
  librsvg2-bin \
  unrar-free \
  python3-numpy \
  python3-lxml \
  python3-tinycss2 \
  python3-cssselect
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "pandoc" "jgm/pandoc" "binary" "latest" "" "pandoc-*-amd64.deb"
fetch_and_deploy_gh_release "calibre" "kovidgoyal/calibre" "prebuild" "latest" "/opt/calibre" "calibre-*-x86_64.txz"
ln -sf /opt/calibre/ebook-convert /usr/bin/ebook-convert
ln -sf /usr/local/bin/ffmpeg /usr/bin/ffmpeg
fetch_and_deploy_gh_release "drawio" "jgraph/drawio-desktop" "binary" "latest" "" "drawio-amd64-*.deb"
fetch_and_deploy_gh_release "transmute" "transmute-app/transmute" "tarball"

msg_info "Setting up Python Backend"
cd /opt/transmute
$STD uv venv --clear /opt/transmute/.venv
$STD uv pip install --python /opt/transmute/.venv/bin/python -r requirements.txt
ln -sf /opt/transmute/.venv/bin/weasyprint /usr/bin/weasyprint
msg_ok "Set up Python Backend"

msg_info "Configuring Transmute"
SECRET_KEY=$(openssl rand -hex 64)
cat <<EOF >/opt/transmute/backend/.env
AUTH_SECRET_KEY=${SECRET_KEY}
HOST=0.0.0.0
PORT=3313
DATA_DIR=/opt/transmute/data
WEB_DIR=/opt/transmute/frontend/dist
QT_QPA_PLATFORM=offscreen
EOF
mkdir -p /opt/transmute/data
msg_ok "Configured Transmute"

msg_info "Building Frontend"
cd /opt/transmute/frontend
$STD npm ci
$STD npm run build
msg_ok "Built Frontend"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/transmute.service
[Unit]
Description=Transmute File Converter
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/transmute
EnvironmentFile=/opt/transmute/backend/.env
ExecStart=/usr/bin/xvfb-run -a -s "-screen 0 1024x768x24 -nolisten tcp" /opt/transmute/.venv/bin/python backend/main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now transmute
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
