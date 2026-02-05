#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wealthfolio.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  pkg-config \
  libssl-dev \
  build-essential \
  libsqlite3-dev \
  argon2
msg_ok "Installed Dependencies"

setup_rust
NODE_MODULE="pnpm" setup_nodejs
fetch_and_deploy_gh_release "wealthfolio" "afadil/wealthfolio" "tarball"

msg_info "Building Frontend (patience)"
cd /opt/wealthfolio
$STD pnpm install --frozen-lockfile
$STD pnpm tsc
$STD pnpm vite build
msg_ok "Built Frontend"

msg_info "Building Backend (patience)"
cd /opt/wealthfolio/src-server
$STD cargo build --release --manifest-path Cargo.toml
cp /opt/wealthfolio/src-server/target/release/wealthfolio-server /usr/local/bin/wealthfolio-server
chmod +x /usr/local/bin/wealthfolio-server
msg_ok "Built Backend"

msg_info "Configuring Wealthfolio"
mkdir -p /opt/wealthfolio_data
SECRET_KEY=$(openssl rand -base64 32)
WF_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-16)
WF_PASSWORD_HASH=$(echo -n "$WF_PASSWORD" | argon2 "$(openssl rand -base64 16)" -id -e)
cat <<EOF >/opt/wealthfolio/.env
WF_LISTEN_ADDR=0.0.0.0:8080
WF_DB_PATH=/opt/wealthfolio_data/wealthfolio.db
WF_SECRET_KEY=${SECRET_KEY}
WF_AUTH_PASSWORD_HASH=${WF_PASSWORD_HASH}
WF_STATIC_DIR=/opt/wealthfolio/dist
WF_CORS_ALLOW_ORIGINS=*
WF_REQUEST_TIMEOUT_MS=30000
EOF
echo "WF_PASSWORD=${WF_PASSWORD}" >~/wealthfolio.creds
msg_ok "Configured Wealthfolio"

msg_info "Cleaning Up"
rm -rf /opt/wealthfolio/src-server/target
rm -rf /root/.cargo/registry
rm -rf /opt/wealthfolio/node_modules
msg_ok "Cleaned Up"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wealthfolio.service
[Unit]
Description=Wealthfolio Investment Tracker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wealthfolio
EnvironmentFile=/opt/wealthfolio/.env
ExecStart=/usr/local/bin/wealthfolio-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wealthfolio
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
