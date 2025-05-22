#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: edoardop13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/favonia/cloudflare-ddns

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

install_go

msg_info "Configure Application"
var_cf_api_token="default"
read -rp "Enter the Cloudflare API token: " var_cf_api_token

var_cf_domains="default"
read -rp "Enter the domains separated with a comma (*.example.org,www.example.org) " var_cf_domains

var_cf_proxied="false"
while true; do
  read -rp "Proxied? (y/n): " answer
  case "$answer" in
  [Yy]*)
    var_cf_proxied="true"
    break
    ;;
  [Nn]*)
    var_cf_proxied="false"
    break
    ;;
  *) echo "Please answer y or n." ;;
  esac
done
var_cf_ip6_provider="none"
while true; do
  read -rp "Enable IPv6 support? (y/n): " answer
  case "$answer" in
  [Yy]*)
    var_cf_ip6_provider="auto"
    break
    ;;
  [Nn]*)
    var_cf_ip6_provider="none"
    break
    ;;
  *) echo "Please answer y or n." ;;
  esac
done
msg_ok "Configured Application"

msg_info "Setting up service"
mkdir -p /root/go
cat <<EOF >/etc/systemd/system/cloudflare-ddns.service
[Unit]
Description=Cloudflare DDNS Service (Go run)
After=network.target

[Service]
Environment="CLOUDFLARE_API_TOKEN=${var_cf_api_token}"
Environment="DOMAINS=${var_cf_domains}"
Environment="PROXIED=${var_cf_proxied}"
Environment="IP6_PROVIDER=${var_cf_ip6_provider}"
Environment="GOPATH=/root/go"
Environment="GOCACHE=/tmp/go-build"
ExecStart=/usr/bin/go/bin/go run github.com/favonia/cloudflare-ddns/cmd/ddns@latest
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cloudflare-ddns
msg_ok "Setup Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
