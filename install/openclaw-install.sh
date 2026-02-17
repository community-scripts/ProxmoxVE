#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: guxie
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openclaw.ai/

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
  python3-setuptools
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing OpenClaw (Patience)"
export SHARP_IGNORE_GLOBAL_LIBVIPS=1
$STD npm install -g openclaw@latest
msg_ok "Installed OpenClaw"

OPENCLAW_BEARER_TOKEN="$(openssl rand -hex 24)"
cat <<EOF >~/openclaw.creds
OpenClaw Gateway
URL: http://${LOCAL_IP}:18789
Gateway Bearer Token: ${OPENCLAW_BEARER_TOKEN}
EOF
chmod 600 ~/openclaw.creds

cat <<EOF >/opt/openclaw.env
OPENCLAW_AUTH_MODE=bearer
OPENCLAW_AUTH_BEARER_TOKEN=${OPENCLAW_BEARER_TOKEN}
OPENCLAW_PORT=18789
EOF
chmod 600 /opt/openclaw.env

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/opt/openclaw.env
ExecStart=openclaw gateway --allow-unconfigured --bind lan --port \${OPENCLAW_PORT} --auth-mode \${OPENCLAW_AUTH_MODE} --auth-bearer-token \${OPENCLAW_AUTH_BEARER_TOKEN}
Restart=always
RestartSec=5
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
