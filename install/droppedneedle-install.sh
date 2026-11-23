#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | Co-Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://droppedneedle.com/ | Github: https://github.com/DroppedNeedle/DroppedNeedle

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ffmpeg \
  python3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "droppedneedle" "DroppedNeedle/DroppedNeedle" "prebuild" "latest" "/opt/droppedneedle" "droppedneedle-v*-$(arch_resolve x86_64 aarch64)-linux.tar.gz"
fetch_and_deploy_gh_release "droppedneedle-frontend" "DroppedNeedle/DroppedNeedle" "prebuild" "latest" "/opt/droppedneedle/frontend" "droppedneedle-frontend-v*.tar.gz"
mkdir -p /opt/droppedneedle/backend/{config,cache,plugins,imports}

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=DROPPEDNEEDLE_STATIC_DIR=/opt/droppedneedle/frontend/static
Environment=PORT=8688
Environment=COMMIT_TAG=v$(<~/.droppedneedle)
Environment=TZ=$(cat /etc/timezone 2>/dev/null || echo Etc/UTC)
# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>
ExecStart=/opt/droppedneedle/droppedneedle
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now droppedneedle
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
