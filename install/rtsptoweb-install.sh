#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y git
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Golang"
$STD wget https://golang.org/dl/go1.20.1.linux-amd64.tar.gz
$STD tar -xzf go1.20.1.linux-amd64.tar.gz -C /usr/local
$STD ln -s /usr/local/go/bin/go /usr/local/bin/go
rm -rf go1.20.1.linux-amd64.tar.gz
msg_ok "Installed Golang"

msg_info "Installing RTSPtoWeb"
$STD git clone https://github.com/deepch/RTSPtoWeb /opt/rtsptoweb
cat <<EOF >>/opt/rtsptoweb/start
#!/bin/bash
cd /opt/rtsptoweb && GO111MODULE=on go run *.go
EOF
chmod +x /opt/rtsptoweb/start
msg_ok "Installed RTSPtoWeb"

msg_info "Creating Service"
service_path="/etc/systemd/system/rtsptoweb.service"
echo "[Unit]
Description=RTSP to Web Streaming Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/rtsptoweb/start

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable -q --now rtsptoweb
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
