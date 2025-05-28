#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/oauth2-proxy/oauth2-proxy/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  jq
msg_ok "Installed Dependencies"

msg_info "Setup OAuth2-Proxy"
RELEASE=$(curl -fsSL https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest | jq -r .tag_name | sed 's/^v//')
mkdir -p /opt/oauth2-proxy
curl -fsSL "https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v${RELEASE}/oauth2-proxy-v${RELEASE}.linux-amd64.tar.gz" -o /opt/oauth2-proxy.tar.gz
tar -xzf /opt/oauth2-proxy.tar.gz -C /opt
mv /opt/oauth2-proxy-v${RELEASE}.linux-amd64/oauth2-proxy /opt/oauth2-proxy
touch /opt/oauth2-proxy/config.toml
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup OAuth2-Proxy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/oauth2-proxy.service
[Unit]
Description=OAuth2-Proxy Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/oauth2-proxy
ExecStart=/opt/oauth2-proxy/oauth2-proxy --config config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now oauth2-proxy
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "/opt/oauth2-proxy.tar.gz"
rm -rf "/opt/oauth2-proxy-v${RELEASE}.linux-amd64"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
