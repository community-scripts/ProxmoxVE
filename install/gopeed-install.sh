#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/GopeedLab/gopeed

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "gopeed" "GopeedLab/gopeed" "prebuild" "latest" "/opt/gopeed" "gopeed-web-v*-linux-$(arch_resolve "amd64" "arm64").zip"

msg_info "Configuring Gopeed"
mkdir -p /opt/gopeed_data/{storage,downloads}
cat <<EOF >/opt/gopeed_data/config.json
{
  "address": "0.0.0.0",
  "port": 9999,
  "username": "gopeed",
  "password": "$(random_password)",
  "apiToken": "$(openssl rand -hex 32)",
  "storageDir": "/opt/gopeed_data/storage",
  "downloadConfig": {
    "downloadDir": "/opt/gopeed_data/downloads"
  }
}
EOF
chmod 600 /opt/gopeed_data/config.json
msg_ok "Configured Gopeed"

msg_info "Creating Gopeed Service"
cat <<EOF >/etc/systemd/system/gopeed.service
[Unit]
Description=Gopeed
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gopeed
ExecStart=/opt/gopeed/gopeed -c /opt/gopeed_data/config.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gopeed
msg_ok "Created Gopeed Service"

motd_ssh
customize
cleanup_lxc
