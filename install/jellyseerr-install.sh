#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.jellyseerr.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    git \
    build-essential
msg_ok "Installed Dependencies"

git clone -q https://github.com/Fallenbagel/jellyseerr.git /opt/jellyseerr
cd /opt/jellyseerr
$STD git checkout main

pnpm_desired=$(grep -Po '"pnpm":\s*"\K[^"]+' /opt/jellyseerr/package.json)
NODE_VERSION="22" NODE_MODULE="pnpm@$pnpm_desired" setup_nodejs

msg_info "Installing Jellyseerr (Patience)"
export CYPRESS_INSTALL_BINARY=0
cd /opt/jellyseerr
$STD pnpm install --frozen-lockfile
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm build
mkdir -p /etc/jellyseerr/
cat <<EOF >/etc/jellyseerr/jellyseerr.conf
PORT=5055
# HOST=0.0.0.0
# JELLYFIN_TYPE=emby
EOF
msg_ok "Installed Jellyseerr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jellyseerr.service
[Unit]
Description=jellyseerr Service
After=network.target

[Service]
EnvironmentFile=/etc/jellyseerr/jellyseerr.conf
Environment=NODE_ENV=production
Type=exec
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jellyseerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
