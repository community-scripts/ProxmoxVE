#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: JD (pentafive)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

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
  curl \
  gnupg \
  build-essential \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Clawdbot"
$STD npm install -g clawdbot
msg_ok "Installed Clawdbot"

msg_info "Creating Configuration"
mkdir -p /opt/clawdbot
cat <<EOF >/opt/clawdbot/config.yaml
# Clawdbot Configuration
# Documentation: https://docs.clawd.bot

# LLM Provider Configuration
# Uncomment and configure your preferred provider(s)

# anthropic:
#   apiKey: "your-anthropic-api-key"

# openai:
#   apiKey: "your-openai-api-key"

# Gateway Settings
gateway:
  port: 3003
  host: "0.0.0.0"

# Webchat (built-in web interface)
webchat:
  enabled: true

# Workspace directory for agent files
workspace: /opt/clawdbot/workspace

# Logging
logging:
  level: info
EOF

mkdir -p /opt/clawdbot/workspace
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/clawdbot.service
[Unit]
Description=Clawdbot AI Assistant Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/clawdbot
ExecStart=/usr/bin/clawdbot gateway start --config /opt/clawdbot/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now clawdbot
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
