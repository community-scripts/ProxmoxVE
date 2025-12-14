#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Eduardo González (wanetty)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wanetty/upgopher

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "upgopher" "wanetty/upgopher" "prebuild" "latest" "/opt/upgopher" "upgopher_*_linux_amd64.tar.gz"

msg_info "Installing Upgopher"
chmod +x /opt/upgopher/upgopher
mkdir -p /opt/upgopher/uploads
msg_ok "Installed Upgopher"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/upgopher.service
[Unit]
Description=Upgopher File Server
Documentation=https://github.com/wanetty/upgopher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/upgopher
ExecStart=/opt/upgopher/upgopher -port 9090 -dir /opt/upgopher/uploads
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now upgopher
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
