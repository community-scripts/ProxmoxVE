#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://flowiseai.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="20" setup_nodejs

msg_info "Installing FlowiseAI (Patience)"
$STD npm install -g flowise \
  @opentelemetry/exporter-trace-otlp-grpc \
  @opentelemetry/exporter-trace-otlp-proto \
  @opentelemetry/sdk-trace-node \
  langchainhub
mkdir -p /opt/flowiseai
curl -fsSL "https://raw.githubusercontent.com/FlowiseAI/Flowise/main/packages/server/.env.example" -o "/opt/flowiseai/.env"
msg_ok "Installed FlowiseAI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/flowise.service
[Unit]
Description=FlowiseAI
After=network.target

[Service]
EnvironmentFile=/opt/flowiseai/.env
ExecStart=npx flowise start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flowise
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
