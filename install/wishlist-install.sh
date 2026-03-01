#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dunky13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cmintey/wishlist

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  build-essential \
  openssl \
  caddy
msg_ok "Installed dependencies"

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
fetch_and_deploy_gh_release "wishlist" "cmintey/wishlist" "tarball"
LATEST_APP_VERSION=$(get_latest_github_release "cmintey/wishlist")

msg_info "Installing Wishlist"
cd /opt/wishlist
cp .env.example .env
sed -i "s|^ORIGIN=.*|ORIGIN=http://${LOCAL_IP}:3280|" /opt/wishlist/.env
echo "" >>/opt/wishlist/.env
echo "NODE_ENV=production" >>/opt/wishlist/.env
$STD pnpm install
$STD pnpm svelte-kit sync
$STD pnpm prisma generate
sed -i 's|/usr/src/app/|/opt/wishlist/|g' $(grep -rl '/usr/src/app/' /opt/wishlist)
export VERSION="v${LATEST_APP_VERSION}"
export SHA="v${LATEST_APP_VERSION}"
$STD pnpm run build
$STD pnpm prune --prod
chmod +x /opt/wishlist/entrypoint.sh
mkdir -p /opt/wishlist/uploads
mkdir -p /opt/wishlist/data
msg_ok "Installed Wishlist"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wishlist.service
[Unit]
Description=Wishlist Service
After=network.target

[Service]
WorkingDirectory=/opt/wishlist
EnvironmentFile=/opt/wishlist/.env
ExecStart=/usr/bin/env sh -c './entrypoint.sh'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wishlist
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
