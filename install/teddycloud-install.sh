#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/toniebox-reverse-engineering/teddycloud

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libubsan1 \
  ffmpeg \
  ca-certificates
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "teddycloud" "toniebox-reverse-engineering/teddycloud" "prebuild" "latest" "/opt/teddycloud" "teddycloud.amd64.release*.zip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/teddycloud.service
[Unit]
Description=TeddyCloud Server
After=network.target

[Service]
User=root
Type=simple
ExecStart=/opt/teddycloud/teddycloud
WorkingDirectory=/opt/teddycloud
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q teddycloud
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
