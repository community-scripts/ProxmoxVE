#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/storybookjs/storybook

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

msg_info "Preparing Storybook"
mkdir -p /opt/storybook
cd /opt/storybook
msg_ok "Important: Interactive configuration will start now."

npx -y storybook@latest init --yes --no-dev
PROJECT_PATH=$(find /opt/storybook -maxdepth 2 -name ".storybook" -type d 2>/dev/null | head -n1 | xargs dirname)

if [[ -z "$PROJECT_PATH" ]]; then
  PROJECT_PATH="/opt/storybook"
fi

cd "$PROJECT_PATH"
echo "$PROJECT_PATH" >/opt/storybook/.projectpath

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/storybook.service
[Unit]
Description=Storybook Dev Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${PROJECT_PATH}
ExecStart=/usr/bin/npx storybook dev --host 0.0.0.0 --port 6006 --no-open
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now storybook
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
