#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/foldergram/foldergram

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y --no-install-recommends ffmpeg
msg_ok "Installed Dependencies"

NODE_VERSION=25 NODE_MODULE="corepack" setup_nodejs

fetch_and_deploy_gh_release "foldergram" "foldergram/foldergram" "tarball"

msg_info "Configuring Foldergram"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
cd /opt/foldergram
$STD pnpm install
$STD pnpm run build
mkdir -p /opt/foldergram_media
cat <<EOF >/opt/foldergram_media/foldergram.env
NODE_ENV=production
SERVER_PORT=4141
DATA_ROOT=/opt/foldergram_media
GALLERY_ROOT=/opt/foldergram_media/gallery
DB_DIR=/opt/foldergram_media/db
THUMBNAILS_DIR=/opt/foldergram_media/thumbnails
PREVIEWS_DIR=/opt/foldergram_media/previews
IMAGE_DETAIL_SOURCE=preview
DERIVATIVE_MODE=eager
GALLERY_EXCLUDED_FOLDERS=
EOF
msg_ok "Configured Foldergram"

msg_info "Creating services"
cat <<EOF >/etc/systemd/system/foldergram.service
[Unit]
Description=Foldergram Service
After=network.target

[Service]
WorkingDirectory=/opt/foldergram
ExecStart=/usr/bin/pnpm start
Restart=always
EnvironmentFile=/opt/foldergram_media/foldergram.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now foldergram
msg_ok "Created services"

motd_ssh
customize
cleanup_lxc
