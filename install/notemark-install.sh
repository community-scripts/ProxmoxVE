#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/enchant97/note-mark

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

setup_go
NODE_VERSION="24" NODE_MODULE="pnpm@11" setup_nodejs
RUST_PROFILE="minimal" setup_rust

fetch_and_deploy_gh_release "notemark" "enchant97/note-mark" "tarball"

msg_info "Building Note Mark"
$STD rustup target add wasm32-unknown-unknown
cd /opt/notemark/frontend
$STD pnpm install --frozen-lockfile
$STD pnpm run wasm
$STD pnpm run build
cd /opt/notemark/backend
$STD go tool sqlc generate
CGO_ENABLED=0 $STD go build -ldflags "-X main.Version=$(cat ~/.notemark)" -o /opt/notemark/note-mark
rm -rf /opt/notemark/frontend/node_modules /opt/notemark/frontend/renderer/target
$STD go clean -cache -modcache
msg_ok "Built Note Mark"

msg_info "Configuring Note Mark"
mkdir -p /opt/notemark_data
cat <<EOF >/opt/notemark_data/.env
BIND__HOST=0.0.0.0
BIND__PORT=8080
DATA_PATH=/opt/notemark_data
STATIC_PATH=/opt/notemark/frontend/dist
PUBLIC_URL=http://${LOCAL_IP}:8080
AUTH_TOKEN__SECRET=$(openssl rand -base64 32)
ENABLE_INTERNAL_SIGNUP=true
EOF
chmod 600 /opt/notemark_data/.env
msg_ok "Configured Note Mark"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/notemark.service
[Unit]
Description=Note Mark
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/notemark_data
EnvironmentFile=/opt/notemark_data/.env
ExecStart=/opt/notemark/note-mark serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now notemark
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
