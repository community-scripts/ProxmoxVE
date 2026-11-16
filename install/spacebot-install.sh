#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/spacedriveapp/spacebot

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  bubblewrap \
  fonts-liberation \
  libnss3 \
  libatk-bridge2.0-0t64 \
  libdrm2 \
  libxcomposite1 \
  libxdamage1 \
  libxrandr2 \
  libgbm1 \
  libasound2t64 \
  libpango-1.0-0 \
  libcairo2 \
  libcups2t64 \
  libxkbcommon0 \
  libxss1 \
  libxtst6 \
  libxfixes3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "spacebot" "spacedriveapp/spacebot" "prebuild" "latest" "/opt/spacebot" "spacebot-v*-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.tar.gz"

msg_info "Configuring Spacebot"
mkdir -p /opt/spacebot_data
cat <<EOF >/opt/spacebot_data/.env
SPACEBOT_DIR=/opt/spacebot_data
EOF
cat <<EOF >/opt/spacebot_data/config.toml
[api]
bind = "0.0.0.0"
port = 19898

[[agents]]
id = "main"
default = true
EOF
if [[ -n "${var_llm_base_url:-}" ]]; then
  cat <<EOF >>/opt/spacebot_data/.env
LLM_API_KEY=${var_llm_api_key:-none}
EOF
  cat <<EOF >>/opt/spacebot_data/config.toml

[llm.provider.custom]
api_type = "openai_chat_completions"
base_url = "${var_llm_base_url%/}"
api_key = "env:LLM_API_KEY"
name = "OpenAI-compatible"

[defaults.routing]
channel = "custom/${var_llm_model}"
branch = "custom/${var_llm_model}"
worker = "custom/${var_llm_model}"
compactor = "custom/${var_llm_model}"
cortex = "custom/${var_llm_model}"
EOF
fi
chmod 600 /opt/spacebot_data/.env /opt/spacebot_data/config.toml
msg_ok "Configured Spacebot"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/spacebot.service
[Unit]
Description=Spacebot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/spacebot_data
EnvironmentFile=/opt/spacebot_data/.env
ExecStart=/opt/spacebot/spacebot start --foreground
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spacebot
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
