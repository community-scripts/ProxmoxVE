#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential
msg_ok "Installed Dependencies"

msg_info "Installing Python3"
$STD apt install -y \
  python3-pip \
  python3-dev \
  python3-venv
mkdir -p ~/.config/pip
cat >~/.config/pip/pip.conf <<EOF
[global]
break-system-packages = true
EOF
msg_ok "Installed Python3"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "paperless-ai" "clusterzx/paperless-ai" "tarball"

msg_info "Setup Paperless-AI"
cd /opt/paperless-ai
$STD python3 -m venv /opt/paperless-ai/venv
source /opt/paperless-ai/venv/bin/activate
# TMPDIR to use container disk instead of tmpfs for large pip downloads (https://github.com/community-scripts/ProxmoxVE/issues/10338)
export TMPDIR=/opt/paperless-ai/tmp
mkdir -p "$TMPDIR"
$STD pip install --upgrade pip
$STD pip install --no-cache-dir -r requirements.txt
rm -rf "$TMPDIR"
mkdir -p data/chromadb
$STD npm ci --only=production
mkdir -p /opt/paperless-ai/data
cat <<EOF >/opt/paperless-ai/data/.env
PAPERLESS_API_URL=
PAPERLESS_API_TOKEN=
PAPERLESS_USERNAME=
AI_PROVIDER=openai
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
OLLAMA_API_URL=
OLLAMA_MODEL=
SCAN_INTERVAL=*/10 * * * *
SYSTEM_PROMPT=""
PROCESS_PREDEFINED_DOCUMENTS=no
TAGS=
ADD_AI_PROCESSED_TAG=no
AI_PROCESSED_TAG_NAME=ki-gen
USE_PROMPT_TAGS=no
PROMPT_TAGS=
USE_EXISTING_DATA=no
API_KEY=
CUSTOM_API_KEY=
CUSTOM_BASE_URL=
CUSTOM_MODEL=
RAG_SERVICE_URL=http://localhost:8000
RAG_SERVICE_ENABLED=true
EOF
msg_ok "Setup Paperless-AI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/paperless-ai.service
[Unit]
Description=PaperlessAI Service
After=network.target paperless-rag.service
Requires=paperless-rag.service

[Service]
WorkingDirectory=/opt/paperless-ai
Environment="NODE_ENV=production"
EnvironmentFile=/opt/paperless-ai/data/.env
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/paperless-rag.service
[Unit]
Description=PaperlessAI-RAG Service
After=network.target

[Service]
WorkingDirectory=/opt/paperless-ai
EnvironmentFile=/opt/paperless-ai/data/.env
ExecStart=/opt/paperless-ai/venv/bin/python3 main.py --host 0.0.0.0 --port 8000 --initialize
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now paperless-rag
sleep 5
systemctl enable -q --now paperless-ai
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
