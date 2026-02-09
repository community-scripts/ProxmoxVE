#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxui.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  logrotate
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "nginx-ui" "0xJacky/nginx-ui" "prebuild" "latest" "/opt/nginx-ui" "nginx-ui-linux-64.tar.gz"

msg_info "Installing Nginx UI"
cp /opt/nginx-ui/nginx-ui /usr/local/bin/nginx-ui
chmod +x /usr/local/bin/nginx-ui
rm -rf /opt/nginx-ui
msg_ok "Installed Nginx UI"

msg_info "Configuring Nginx UI"
mkdir -p /usr/local/etc/nginx-ui
cat <<EOF >/usr/local/etc/nginx-ui/app.ini
[app]
PageSize = 10

[server]
Host = 0.0.0.0
Port = 9000
RunMode = release

[cert]
HTTPChallengePort = 9180

[terminal]
StartCmd = login
EOF
msg_ok "Configured Nginx UI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nginx-ui.service
[Unit]
Description=Another WebUI for Nginx
Documentation=https://nginxui.com
After=network.target nginx.service

[Service]
Type=simple
ExecStart=/usr/local/bin/nginx-ui --config /usr/local/etc/nginx-ui/app.ini
RuntimeDirectory=nginx-ui
WorkingDirectory=/var/run/nginx-ui
Restart=on-failure
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
msg_ok "Created Service"

msg_info "Starting Service"
systemctl enable -q --now nginx-ui
rm -rf /etc/nginx/sites-enabled/default
msg_ok "Started Service"

motd_ssh
customize
cleanup_lxc
