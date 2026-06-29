#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: John McLear (JohnMcLear)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://etherpad.org

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
  libsqlite3-dev
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs

msg_info "Enabling pnpm via corepack"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
msg_ok "Enabled pnpm"

fetch_and_deploy_gh_release "etherpad-lite" "ether/etherpad" "tarball"

msg_info "Building Etherpad"
cd /opt/etherpad-lite
$STD pnpm install --frozen-lockfile
$STD pnpm run build:etherpad
msg_ok "Built Etherpad"

msg_info "Configuring Etherpad"
cp /opt/etherpad-lite/settings.json.template /opt/etherpad-lite/settings.json
mkdir -p /var/lib/etherpad
sed -i \
  -e 's#"ip": *"127.0.0.1"#"ip": "0.0.0.0"#' \
  -e 's#"dbType" *: *"dirty"#"dbType": "sqlite"#' \
  -e 's#"filename" *: *"var/dirty.db"#"filename": "/var/lib/etherpad/etherpad.db"#' \
  /opt/etherpad-lite/settings.json
msg_ok "Configured Etherpad"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/etherpad.service
[Unit]
Description=Etherpad Collaborative Editor
Documentation=https://etherpad.org/doc
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/etherpad-lite
Environment=NODE_ENV=production
Environment=COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ExecStart=/usr/bin/pnpm run prod
Restart=always
RestartSec=5
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now etherpad
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
