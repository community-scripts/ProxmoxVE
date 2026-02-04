#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ca-certificates \
  build-essential \
  python3 \
  python3-setuptools \
  graphicsmagick
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing n8n (Patience)"
$STD npm install --global patch-package
$STD npm install --global n8n
msg_ok "Installed n8n"

msg_info "Creating Service"
mkdir -p /opt
cat <<EOF >/opt/n8n.env
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=${LOCAL_IP}
EOF

cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n

[Service]
Type=simple
EnvironmentFile=/opt/n8n.env
ExecStart=n8n start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now n8n
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
