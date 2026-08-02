#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: (AminGholizad)
# License: MIT | https://github.com/AminGholizad/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/PanSalut/Koffan

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

setup_go
fetch_and_deploy_gh_release "koffan" "PanSalut/Koffan" "tarball"

msg_info "Building Koffan"
cd /opt/koffan
$STD go build -o koffan main.go
msg_ok "Built Koffan"

msg_info "Configuring Koffan"
APP_PASSWD=$(openssl rand -base64 12)
mkdir /opt/koffan/data
cat <<EOF >/opt/koffan/data/.env
APP_ENV=production
APP_PASSWORD=${APP_PASSWD}
PORT=3000
DB_PATH=/opt/koffan/data/shopping.db
EOF
cat <<EOF >~/koffan.creds
Password: ${APP_PASSWD}
EOF
msg_ok "Configured Koffan"

msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/koffan.service
[Unit]
Description=Koffan Service
After=network.target

[Service]
EnvironmentFile=/opt/koffan/data/.env
WorkingDirectory=/opt/koffan
ExecStart=/opt/koffan/koffan
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now koffan
msg_ok "Created systemd service"

motd_ssh
customize
cleanup_lxc
