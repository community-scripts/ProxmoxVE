#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bambanah/deemix

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

fetch_and_deploy_gh_release "deemix" "bambanah/deemix" "tarball" "latest" "/opt/deemix" "" "deemix-webui@"
NODE_VERSION="24" NODE_MODULE="pnpm@$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/deemix/package.json)" setup_nodejs

msg_info "Building Deemix"
cd /opt/deemix
ELECTRON_SKIP_BINARY_DOWNLOAD=1 $STD pnpm install --frozen-lockfile
$STD pnpm turbo build --filter=deemix-webui...
msg_ok "Built Deemix"

msg_info "Creating Service"
mkdir -p /opt/deemix_data/{config,music}
cat <<EOF >/etc/systemd/system/deemix.service
[Unit]
Description=Deemix
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/deemix
Environment=NODE_ENV=production
Environment=DEEMIX_DATA_DIR=/opt/deemix_data/config
Environment=DEEMIX_MUSIC_DIR=/opt/deemix_data/music
Environment=DEEMIX_SERVER_PORT=6595
Environment=DEEMIX_HOST=0.0.0.0
Environment=DEEMIX_SINGLE_USER=true
ExecStart=/usr/bin/node /opt/deemix/packages/webui/dist/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now deemix
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
