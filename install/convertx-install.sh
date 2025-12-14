#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Omar Minaya | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/C4illin/ConvertX

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_imagemagick

msg_info "Installing Dependencies"
$STD apt-get install -y \
  assimp-utils \
  calibre \
  dcraw \
  dvisvgm \
  ffmpeg \
  inkscape \
  libva2 \
  libvips-tools \
  lmodern \
  mupdf-tools \
  pandoc \
  poppler-utils \
  potrace \
  python3-numpy \
  texlive \
  texlive-fonts-recommended \
  texlive-latex-extra \
  texlive-latex-recommended \
  texlive-xetex
msg_ok "Installed Dependencies"

NODE_VERSION=22 NODE_MODULE="bun" setup_nodejs
fetch_and_deploy_gh_release "ConvertX" "C4illin/ConvertX" "tarball" "latest" "/opt/convertx"

msg_info "Installing ConvertX"
cd /opt/convertx
mkdir -p data
$STD bun install

JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
cat <<EOF >/opt/convertx/.env
JWT_SECRET=$JWT_SECRET
HTTP_ALLOWED=true
PORT=3000
EOF
msg_ok "Installed ConvertX"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/convertx.service
[Unit]
Description=ConvertX File Converter
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/convertx
EnvironmentFile=/opt/convertx/.env
ExecStart=/bin/bun dev
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now convertx
msg_ok "Service Created"

motd_ssh
customize
cleanup_lxc
