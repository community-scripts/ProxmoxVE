#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jhaals/yopass

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
systemctl enable -q --now redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "yopass" "jhaals/yopass" "tarball"
GO_VERSION="$(grep -m1 '^go ' /opt/yopass/go.mod | awk '{print $2}')" setup_go

msg_info "Building Yopass"
cd /opt/yopass
$STD go build -ldflags "-X main.version=$(cat ~/.yopass)" ./cmd/yopass-server
cd /opt/yopass/website
$STD yarn install --network-timeout 600000
$STD yarn build
msg_ok "Built Yopass"

msg_info "Generating SSL Certificate"
mkdir -p /opt/yopass/certificates
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /opt/yopass/certificates/key.pem \
  -out /opt/yopass/certificates/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Yopass/CN=${LOCAL_IP}" \
  -addext "subjectAltName=IP:${LOCAL_IP},DNS:localhost,IP:127.0.0.1" \
  2>/dev/null
chmod 600 /opt/yopass/certificates/key.pem
chmod 644 /opt/yopass/certificates/cert.pem
msg_ok "Generated SSL Certificate"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/yopass.service
[Unit]
Description=Yopass
Wants=network-online.target
After=network-online.target redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/yopass
ExecStart=/opt/yopass/yopass-server --address 0.0.0.0 --port 1337 --tls-cert /opt/yopass/certificates/cert.pem --tls-key /opt/yopass/certificates/key.pem --database redis --redis redis://127.0.0.1:6379/0 --asset-path /opt/yopass/website/dist
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now yopass
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
