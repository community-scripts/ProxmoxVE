#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://ztnet.network

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  jq \
  git \
  openssl \
  gnupg
msg_ok "Installed Dependencies"

PG_DB_NAME="ztnet" PG_DB_USER="ztnet" setup_postgresql_db

NODE_VERSION="20" setup_nodejs

msg_info "Installing ZeroTier"
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then
  echo "$z" | bash
fi
$STD systemctl enable --now zerotier-one
msg_ok "Installed ZeroTier"

fetch_and_deploy_gh_release "ztnet" "sinamics/ztnet" "tarball" "latest" "/opt/ztnet"

msg_info "Setting up Application"
cd /opt/ztnet || exit
export NODE_OPTIONS=--dns-result-order=ipv4first
$STD npm install
msg_ok "Set up Application"

import_local_ip

msg_info "Configuring Environment"
ZT_SECRET=""
if [[ -f /var/lib/zerotier-one/authtoken.secret ]]; then
  ZT_SECRET=$(cat /var/lib/zerotier-one/authtoken.secret)
fi

NEXTAUTH_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/ztnet/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}?schema=public
NEXTAUTH_URL=http://${LOCAL_IP}:3000
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
ZT_ADDR=http://127.0.0.1:9993
ZT_SECRET=${ZT_SECRET}
EOF
msg_ok "Configured Environment"

msg_info "Running Database Migrations"
export DATABASE_URL="postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}?schema=public"
$STD npx prisma migrate deploy
$STD npx prisma db seed
msg_ok "Database Migrations Complete"

msg_info "Building Application"
$STD npm run build
msg_ok "Built Application"

msg_info "Copying ztmkworld Binary"
ARCH=$(uname -m)
case "$ARCH" in
  "x86_64") ZTM_ARCH="amd64" ;;
  "aarch64") ZTM_ARCH="arm64" ;;
  *) ZTM_ARCH="$ARCH" ;;
esac
if [[ -f "/opt/ztnet/ztnodeid/build/linux_${ZTM_ARCH}/ztmkworld" ]]; then
  cp "/opt/ztnet/ztnodeid/build/linux_${ZTM_ARCH}/ztmkworld" /usr/local/bin/ztmkworld
  chmod +x /usr/local/bin/ztmkworld
fi
msg_ok "Copied ztmkworld Binary"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ztnet.service
[Unit]
Description=ZTNet - ZeroTier Network Controller
After=network.target postgresql.service zerotier-one.service
Wants=postgresql.service zerotier-one.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ztnet
Environment=NODE_ENV=production
Environment=NODE_OPTIONS=--dns-result-order=ipv4first
ExecStart=/usr/bin/node /opt/ztnet/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ztnet
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
