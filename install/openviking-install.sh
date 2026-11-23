#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Marcos Felipe (mfelipe)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/volcengine/OpenViking

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y openssl
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing OpenViking"
$STD uv venv --python 3.12 /opt/openviking
$STD uv pip install --python /opt/openviking/bin/python openviking
cat <<EOF >~/.openviking-server
$(get_latest_github_release "volcengine/OpenViking")
EOF
msg_ok "Installed OpenViking"

msg_info "Configuring OpenViking"
ROOT_API_KEY=$(openssl rand -hex 32)
mkdir -p /opt/openviking_data
cat <<EOF >/opt/openviking_data/ov.conf
{
  "server": {
    "host": "0.0.0.0",
    "port": 1933,
    "root_api_key": "${ROOT_API_KEY}",
    "cors_origins": ["*"]
  },
  "storage": {
    "workspace": "/opt/openviking_data/data",
    "agfs": { "backend": "local" },
    "vectordb": { "backend": "local" }
  },
  "embedding": {
    "dense": {
      "api_base": "https://api.openai.com/v1",
      "api_key": "REPLACE_WITH_YOUR_EMBEDDING_API_KEY",
      "provider": "openai",
      "dimension": 1536,
      "model": "text-embedding-3-small"
    }
  },
  "vlm": {
    "api_base": "https://api.openai.com/v1",
    "api_key": "REPLACE_WITH_YOUR_VLM_API_KEY",
    "provider": "openai",
    "model": "gpt-4o"
  }
}
EOF
chmod 600 /opt/openviking_data/ov.conf
msg_ok "Configured OpenViking"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openviking.service
[Unit]
Description=OpenViking HTTP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openviking_data
Environment="OPENVIKING_CONFIG_FILE=/opt/openviking_data/ov.conf"
ExecStart=/opt/openviking/bin/openviking-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openviking

ready=0
for _ in {1..60}; do
  if curl -fsS -o /dev/null "http://127.0.0.1:1933/health"; then
    ready=1
    break
  fi
  sleep 2
done
if [[ "$ready" -ne 1 ]]; then
  msg_warn "OpenViking did not become healthy within 120 seconds — check 'systemctl status openviking'"
fi
msg_ok "Created Service"

msg_info "Running OpenViking Doctor"
if OPENVIKING_CONFIG_FILE=/opt/openviking_data/ov.conf /opt/openviking/bin/openviking-server doctor >/dev/null 2>&1; then
  msg_ok "Doctor check passed"
else
  msg_warn "Doctor check reported warnings — configure the model API keys in /opt/openviking_data/ov.conf and restart the service"
fi

motd_ssh
customize
cleanup_lxc
