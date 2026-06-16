#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jeffvli/feishin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  gettext-base
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "feishin" "jeffvli/feishin" "tarball"

msg_info "Building Feishin Web"
cd /opt/feishin
#PNPM_VERSION=$(jq -r '.packageManager | ltrimstr("pnpm@")' /opt/feishin/package.json)
$STD corepack enable
$STD corepack prepare "pnpm@10" --activate
$STD pnpm install
$STD pnpm run build:web
msg_ok "Built Feishin Web"

msg_info "Configuring Environment"
cat <<EOF >/opt/feishin/.env
SERVER_NAME=jellyfin
SERVER_LOCK=false
SERVER_TYPE=jellyfin
SERVER_URL=http://localhost:8096
REMOTE_URL=
LEGACY_AUTHENTICATION=false
ANALYTICS_DISABLED=false
PUBLIC_PATH=/
EOF
msg_ok "Configured Environment"

msg_info "Publishing Web Assets"
rm -rf /usr/share/nginx/html
mkdir -p /usr/share/nginx/html
cp -r /opt/feishin/out/web/. /usr/share/nginx/html/

set -a
source /opt/feishin/.env
set +a

envsubst </opt/feishin/settings.js.template >/etc/nginx/conf.d/settings.js
envsubst '${PUBLIC_PATH}' </opt/feishin/ng.conf.template >/etc/nginx/sites-available/feishin

ln -sf /etc/nginx/sites-available/feishin /etc/nginx/sites-enabled/feishin
rm -f /etc/nginx/sites-enabled/default
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "Published Web Assets"

motd_ssh
customize
cleanup_lxc
