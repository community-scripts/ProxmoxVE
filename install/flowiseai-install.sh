#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://flowiseai.com/ | Github: https://github.com/FlowiseAI/Flowise

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  pkg-config
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.11" setup_uv
NODE_VERSION="22" setup_nodejs #needed because better-sql break

msg_info "Installing FlowiseAI (Patience)"
PYTHON_BIN="$(uv python find 3.11)"
export npm_config_python="$PYTHON_BIN"
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
ExecStart=flowise start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flowise
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
