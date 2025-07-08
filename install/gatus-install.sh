#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates \
  libcap2-bin
msg_ok "Installed Dependencies"

setup_go
fetch_and_deploy_gh_release "gatus" "TwiN/gatus"

msg_info "Configuring gatus"
cd /opt/gatus
$STD go mod tidy
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
setcap CAP_NET_RAW+ep gatus
mv config.yaml config
msg_ok "Configured gatus"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gatus.service
[Unit]
Description=gatus Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gatus
ExecStart=/opt/gatus/gatus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gatus
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
