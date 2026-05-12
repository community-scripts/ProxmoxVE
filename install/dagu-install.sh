#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dagu.sh/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "dagu" "dagucloud/dagu" "prebuild" "latest" "/opt/dagu" "dagu_*_linux_amd64.tar.gz"

msg_info "Setting up Dagu"
mkdir -p /opt/dagu/data
msg_ok "Set up Dagu"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dagu.service
[Unit]
Description=Dagu Workflow Engine
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dagu
Environment=DAGU_HOME=/opt/dagu/data
Environment=DAGU_HOST=0.0.0.0
Environment=DAGU_PORT=8080
ExecStart=/opt/dagu/dagu start-all
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now dagu
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
