#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs

msg_info "Installing Fumadocs"
mkdir -p /opt/fumadocs
cd /opt/fumadocs
pnpm create fumadocs-app
PROJECT_NAME=$(find . -maxdepth 1 -type d ! -name '.' ! -name '..' | sed 's|^\./||')
echo "$PROJECT_NAME" >/opt/fumadocs/.projectname
msg_ok "Installed Fumadocs"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fumadocs_$PROJECT_NAME.service
[Unit]
Description=Fumadocs Documentation Server
After=network.target

[Service]
WorkingDirectory=/opt/fumadocs/$PROJECT_NAME
ExecStart=/usr/bin/pnpm run dev
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fumadocs_$PROJECT_NAME
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
