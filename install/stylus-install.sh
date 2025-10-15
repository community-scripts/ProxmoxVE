#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mmastrac/stylus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "stylus" "mmastrac/stylus" "singlefile" "latest" "/usr/bin/" "*_linux_amd64"

msg_info "Configuring Stylus"
$STD stylus init /opt/stylus/
msg_ok "Configured Stylus"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/stylus.service
[Unit]
Description=Stylus Service
After=network.target

[Service]
Type=simple
ExecStart=stylus run /opt/stylus/
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stylus
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned up"
