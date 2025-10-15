#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
  python3-pip
msg_ok "Installed Python3"

setup_nodejs

msg_info "Setup Paperless-AI"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/clusterzx/paperless-ai/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/clusterzx/paperless-ai/archive/refs/tags/v${RELEASE}.zip" -o "v${RELEASE}.zip"
$STD unzip v${RELEASE}.zip
mv paperless-ai-${RELEASE} /opt/paperless-ai
cd /opt/paperless-ai
$STD pip install --no-cache-dir -r requirements.txt
mkdir -p data/chromadb
$STD npm install
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
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Paperless-AI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/paperless-ai.service
[Unit]
Description=PaperlessAI Service
After=network.target paperless-rag.service
Requires=paperless-rag.service

[Service]
WorkingDirectory=/opt/paperless-ai
ExecStart=/usr/bin/npm start
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
ExecStart=/usr/bin/python3 main.py --host 0.0.0.0 --port 8000 --initialize
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

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
