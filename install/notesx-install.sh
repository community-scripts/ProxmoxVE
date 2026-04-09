#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Hotfirenet
# License: MIT | https://github.com/Hotfirenet/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/note-sx/server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "notesx" "note-sx/server" "tarball" "latest" "/opt/notesx"

msg_info "Building NoteSX"
cd /opt/notesx/app
$STD npm install --omit=dev
$STD npx tsc --noCheck
msg_ok "Built NoteSX"

msg_info "Configuring NoteSX"
HASH_SALT=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c32)
cat <<EOF >/opt/notesx/app/.env
BASE_WEB_URL=http://localhost:3000
HASH_SALT=${HASH_SALT}
MAXIMUM_UPLOAD_SIZE_MB=5
FOLDER_PREFIX=0
ALLOW_NEW_USERS=true
NODE_ENV=production
EOF
msg_ok "Configured NoteSX"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/notesx.service
[Unit]
Description=NoteXS Share Note Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/notesx/app
EnvironmentFile=/opt/notesx/app/.env
ExecStart=/usr/bin/node /opt/notesx/app/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now notesx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
