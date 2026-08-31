#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Karolis Stanelis (kstanelis)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

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
  pkg-config \
  libcairo2-dev \
  libpango1.0-dev \
  libjpeg-dev \
  libgif-dev \
  libpixman-1-dev \
  librsvg2-dev
msg_ok "Installed Dependencies"

NODE_VERSION="26" setup_nodejs

fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball" "latest" "/opt/maintainerr"

msg_info "Building Maintainerr (Patience)"
cd /opt/maintainerr
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export NODE_OPTIONS="--max-old-space-size=4096"
$STD corepack enable
$STD corepack prepare yarn@4.11.0 --activate
$STD yarn config set enableTelemetry 0
$STD yarn install --network-timeout 300000
$STD yarn turbo build --concurrency=1
cp -r apps/ui/dist apps/server/dist/ui
cp -r apps/server/assets apps/server/dist/assets
find apps/server/dist/ui -type f -not -path '*/node_modules/*' -print0 | xargs -0 sed -i "s,/__PATH_PREFIX__,,g"
$STD yarn workspaces focus --all --production
rm -rf /opt/maintainerr/.yarn/cache /opt/maintainerr/.turbo /opt/maintainerr/apps/ui
msg_ok "Built Maintainerr"

msg_info "Configuring Environment"
mkdir -p /opt/data/logs
ln -sfn /opt/maintainerr /opt/app
cat <<EOF >/opt/maintainerr/.env
NODE_ENV=production
DATA_DIR=/opt/data
UI_PORT=6246
UI_HOSTNAME=0.0.0.0
BASE_PATH=
VERSION_TAG=stable
npm_package_version=$(cat ~/.maintainerr)
EOF
msg_ok "Configured Environment"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/maintainerr.service
[Unit]
Description=Maintainerr
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/maintainerr/apps/server
EnvironmentFile=/opt/maintainerr/.env
ExecStart=/usr/bin/node dist/main
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now maintainerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
