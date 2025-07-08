#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/excalidraw/excalidraw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y xdg-utils
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
fetch_and_deploy_gh_release "excalidraw" "excalidraw/excalidraw"

msg_info "Configuring Excalidraw"
cd /opt/excalidraw
$STD yarn
msg_ok "Setup Excalidraw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/excalidraw.service
[Unit]
Description=Excalidraw Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/excalidraw
ExecStart=/usr/bin/yarn start --host
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now excalidraw
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
