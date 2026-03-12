#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

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
  ca-certificates \
  curl \
  git \
  python3 \
  sqlite3
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball" "latest" "/opt/app"

msg_info "Enabling Corepack for Yarn"
cd /opt/app || exit
$STD corepack enable
$STD corepack prepare yarn@4.11.0 --activate
msg_ok "Enabled Corepack"

msg_info "Installing Dependencies"
$STD yarn install --network-timeout 99999999
msg_ok "Installed Dependencies"

msg_info "Building Application"
$STD yarn turbo build
msg_ok "Built Application"

msg_info "Installing Production Dependencies"
$STD yarn workspaces focus --all --production
msg_ok "Installed Production Dependencies"

msg_info "Copying UI Files to Server"
cp -r /opt/app/apps/ui/dist /opt/app/apps/server/dist/ui
msg_ok "Copied UI Files"

msg_info "Creating Data Directory"
mkdir -p /opt/data/logs
msg_ok "Created Data Directory"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/maintainerr.service
[Unit]
Description=Maintainerr - Media Collection Manager
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment=NODE_ENV=production
Environment=DATA_DIR=/opt/data
Environment=UI_PORT=6246
Environment=UI_HOSTNAME=0.0.0.0
ExecStart=/usr/bin/node apps/server/dist/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now maintainerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
