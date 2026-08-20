#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# Co-Authors: yusing
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/yusing/godoxy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "godoxy" "yusing/godoxy" "singlefile" "latest" "/opt/godoxy" "godoxy-linux-$(arch_resolve)"

msg_info "Generating Self-Signed Certificate"
create_self_signed_cert "godoxy"
msg_ok "Generated Self-Signed Certificate"

msg_info "Configuring GoDoxy"
mkdir -p \
  /opt/godoxy/config/middlewares \
  /opt/godoxy/data \
  /opt/godoxy/error_pages

cat <<EOF >/opt/godoxy/config/config.yml
autocert:
  provider: local
  cert_path: /etc/ssl/godoxy/godoxy.crt
  key_path: /etc/ssl/godoxy/godoxy.key

providers:
  include:
    - routes.yml

webui:
  aliases:
    - "${LOCAL_IP}"
EOF

cat <<'EOF' >/opt/godoxy/config/routes.yml
{}
EOF

cat <<EOF >/etc/godoxy.env
GODOXY_API_USER="admin"
GODOXY_API_PASSWORD="$(openssl rand -hex 16)"
GODOXY_API_JWT_SECRET="$(openssl rand -base64 32)"
EOF
chmod 600 /etc/godoxy.env
msg_ok "Configured GoDoxy"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/godoxy.service
[Unit]
Description=GoDoxy Reverse Proxy
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/godoxy
EnvironmentFile=/etc/godoxy.env
ExecStart=/opt/godoxy/godoxy
Restart=on-failure
RestartSec=5
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full
ReadWritePaths=/opt/godoxy /etc/ssl/godoxy
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now godoxy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
