#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mathiasnagler
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/router-for-me/CLIProxyAPI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y openssl
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "cliproxyapi" "router-for-me/CLIProxyAPI" "prebuild" "latest" "/opt/cliproxyapi" "CLIProxyAPI_*_linux_amd64.tar.gz"

msg_info "Configuring CLIProxyAPI"
MANAGEMENT_PASSWORD=$(openssl rand -hex 32)
API_KEY="sk-$(openssl rand -hex 16)"
cat <<EOF >/opt/cliproxyapi/config.yaml
host: ""
port: 8317
auth-dir: "/root/.cli-proxy-api"
remote-management:
  allow-remote: true
  secret-key: "${MANAGEMENT_PASSWORD}"
api-keys:
  - "${API_KEY}"
request-retry: 3
quota-exceeded:
  switch-project: true
  switch-preview-model: true
routing:
  strategy: "round-robin"
EOF
msg_ok "Configured CLIProxyAPI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cliproxyapi.service
[Unit]
Description=CLIProxyAPI
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/cliproxyapi
ExecStart=/opt/cliproxyapi/cli-proxy-api
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cliproxyapi
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
