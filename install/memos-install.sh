#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usememos/memos

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  curl \
  sudo \
  tzdata \
  mc
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing pnpm"
$STD npm install -g pnpm
msg_ok "Installed pnpm"

msg_info "Installing Golang"
set +o pipefail
GOLANG=$(curl -s https://go.dev/dl/ | grep -o "go.*\linux-amd64.tar.gz" | head -n 1)
wget -q https://golang.org/dl/$GOLANG
tar -xzf $GOLANG -C /usr/local
ln -s /usr/local/go/bin/go /usr/local/bin/go
set -o pipefail
msg_ok "Installed Golang"

msg_info "Installing Memos (Patience)"
mkdir -p /opt/memos_data
$STD sudo git clone https://github.com/usememos/memos.git /opt/memos
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
systemctl enable -q --now memos.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
