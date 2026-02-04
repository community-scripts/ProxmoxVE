#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="openclaw" setup_nodejs

msg_info "Setup OpenClaw"
mkdir -p /root/.openclaw
cat <<CONF >/root/.openclaw/openclaw.json
{
  "gateway": {
    "bind": "lan",
    "port": 18789
  }
}
CONF
msg_ok "Setup OpenClaw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openclaw gateway --allow-unconfigured --port 18789 --bind lan
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=/usr/bin:/usr/local/bin:/bin

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q openclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
