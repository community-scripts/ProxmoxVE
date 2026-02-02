#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://readeck.org/en/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_codeberg_release "readeck" "readeck/readeck" "singlefile" "latest" "/opt/readeck" "readeck-*-linux-amd64"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/readeck.service
[Unit]
Description=Readeck Service
After=network.target

[Service]
Environment=READECK_SERVER_HOST=0.0.0.0
Environment=READECK_SERVER_PORT=8000
ExecStart=/opt/readeck/./readeck serve
WorkingDirectory=/opt/readeck
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now readeck
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
