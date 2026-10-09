#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dashy.to/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs
fetch_and_deploy_gh_release "dashy" "Lissy93/dashy" "prebuild" "latest" "/opt/dashy" "dashy-*.tar.gz"

msg_info "Installing Dashy"
cd /opt/dashy
$STD yarn install --ignore-engines --network-timeout 300000
msg_ok "Installed Dashy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dashy.service
[Unit]
Description=dashy

[Service]
Type=simple
WorkingDirectory=/opt/dashy
ExecStart=/usr/bin/node server.js
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now dashy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
