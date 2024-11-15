#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Cloudflared"
mkdir -p --mode=0755 /usr/share/keyrings
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg >/usr/share/keyrings/cloudflare-main.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $VERSION main" >/etc/apt/sources.list.d/cloudflared.list
$STD apt-get update
$STD apt-get install -y cloudflared
msg_ok "Installed Cloudflared"

read -r -p "Would you like to configure cloudflared as a DNS-over-HTTPS (DoH) proxy? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Creating Service"
  cat <<EOF >/usr/local/etc/cloudflared/config.yml
proxy-dns: true
proxy-dns-address: 0.0.0.0
proxy-dns-port: 53
proxy-dns-max-upstream-conns: 5
proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://1.0.0.1/dns-query
  #- https://8.8.8.8/dns-query
  #- https://8.8.4.4/dns-query
  #- https://9.9.9.9/dns-query
  #- https://149.112.112.112/dns-query
EOF
  cat <<EOF >/etc/systemd/system/cloudflared.service
[Unit]
Description=cloudflared DNS-over-HTTPS (DoH) proxy
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared --config /usr/local/etc/cloudflared/config.yml
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now cloudflared.service
  msg_ok "Created Service"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
