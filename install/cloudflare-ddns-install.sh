#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

var_cf_api_token="default"
read -rp "${TAB3}Enter the Cloudflare API token: " var_cf_api_token

var_cf_domains="default"
read -rp "${TAB3}Enter the domains separated with a comma (*.example.org,www.example.org) " var_cf_domains

var_cf_proxied="false"
while true; do
  read -rp "${TAB3}Proxied? (y/n): " answer
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
  read -rp "${TAB3}Enable IPv6 support? (y/n): " answer
  case "$answer" in
  [Yy]*)
    var_cf_ip6_provider="cloudflare.trace"
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

fetch_and_deploy_gh_release "cloudflare-ddns" "favonia/cloudflare-ddns" "tarball"
GO_VERSION="$(grep -m1 '^go ' /opt/cloudflare-ddns/go.mod | awk '{print $2}')" setup_go

msg_info "Building ${APPLICATION}"
cd /opt/cloudflare-ddns
export CGO_ENABLED=0 GOOS=linux
$STD go build -trimpath -ldflags="-s -w" -o /usr/local/bin/ddns ./cmd/ddns
msg_ok "Built ${APPLICATION}"

# The binary is statically linked (CGO_ENABLED=0), so Go is only a build-time
# dependency. Removing it keeps the container small; update_script reinstalls it
# via setup_go when a rebuild is needed.
msg_info "Removing Build Dependencies"
rm -rf /usr/local/go /usr/local/bin/go /usr/local/bin/gofmt /root/go /root/.cache/go-build /opt/cloudflare-ddns
msg_ok "Removed Build Dependencies"

msg_info "Setting up service"
useradd --system --no-create-home --shell /usr/sbin/nologin cloudflare-ddns 2>/dev/null || true
cat <<EOF >/etc/cloudflare-ddns.env
CLOUDFLARE_API_TOKEN=${var_cf_api_token}
DOMAINS=${var_cf_domains}
PROXIED=${var_cf_proxied}
IP6_PROVIDER=${var_cf_ip6_provider}
EOF
chown root:root /etc/cloudflare-ddns.env
chmod 600 /etc/cloudflare-ddns.env
cat <<EOF >/etc/systemd/system/cloudflare-ddns.service
[Unit]
Description=Cloudflare DDNS Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=cloudflare-ddns
Group=cloudflare-ddns
EnvironmentFile=/etc/cloudflare-ddns.env
ExecStart=/usr/local/bin/ddns
Restart=always
RestartSec=300
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cloudflare-ddns
msg_ok "Setup Service"

motd_ssh
customize
cleanup_lxc
