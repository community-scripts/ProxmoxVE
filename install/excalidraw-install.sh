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
$STD apt-get install -y \
  xdg-utils
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Setup Excalidraw"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/excalidraw/excalidraw/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/excalidraw/excalidraw/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar xzf $temp_file
mv excalidraw-${RELEASE} /opt/excalidraw
cd /opt/excalidraw
$STD yarn
echo "${RELEASE}" >/opt/excalidraw_version.txt
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
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
