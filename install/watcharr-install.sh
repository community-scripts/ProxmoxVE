#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sbondCo/Watcharr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y gcc
msg_ok "Installed Dependencies"

setup_go
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "watcharr" "sbondCo/Watcharr" "tarball"

msg_info "Setup Watcharr"
cd /opt/watcharr
$STD npm i
$STD npm run build
mv ./build ./server/ui
cd server
export CGO_ENABLED=1 GOOS=linux
go mod download
go build -o ./watcharr
msg_ok "Setup Watcharr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/watcharr.service
[Unit]
Description=Watcharr Service
After=network.target

[Service]
WorkingDirectory=/opt/watcharr/server
ExecStart=/opt/watcharr/server/watcharr
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now watcharr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
