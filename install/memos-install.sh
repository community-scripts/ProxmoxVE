#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usememos/memos

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential \
  git \
  tzdata
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
setup_go

msg_info "Installing Memos (Patience)"
mkdir -p /opt/memos_data
export NODE_OPTIONS="--max-old-space-size=2048"
$STD git clone https://github.com/usememos/memos.git /opt/memos
cd /opt/memos/web
$STD pnpm i --frozen-lockfile
$STD pnpm build
cd /opt/memos
mkdir -p /opt/memos/server/dist
cp -r web/dist/* /opt/memos/server/dist/
cp -r web/dist/* /opt/memos/server/router/frontend/dist/
$STD go build -o /opt/memos/memos -tags=embed bin/memos/main.go
msg_ok "Installed Memos"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/memos.service
[Unit]
Description=Memos Server
After=network.target

[Service]
ExecStart=/opt/memos/memos
Environment="MEMOS_MODE=prod"
Environment="MEMOS_PORT=9030"
Environment="MEMOS_DATA=/opt/memos_data"
WorkingDirectory=/opt/memos
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now memos
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
