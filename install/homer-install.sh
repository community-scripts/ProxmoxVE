#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bastienwirtz/homer

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "homer" "bastienwirtz/homer" "prebuild" "latest" "/opt/homer" "homer.zip"
cp /opt/homer/assets/config.yml.dist /opt/homer/assets/config.yml

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homer.service
[Unit]
Description=Homer Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/homer
ExecStart=python3 -m http.server 8010

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homer
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
