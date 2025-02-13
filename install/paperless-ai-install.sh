#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
	curl \
	sudo \
	mc \
	gpg \
  make \
  gcc \
  g++ \
  build-essential
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Setup Paperless-AI"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/clusterzx/paperless-ai/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/clusterzx/paperless-ai/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv paperless-ai-${RELEASE} /opt/paperless-ai
cd /opt/paperless-ai
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
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Paperless-AI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/paperless-ai.service
[Unit]
Description=PaperlessAI Service
After=network.target

[Service]
WorkingDirectory=/opt/paperless-ai
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now paperless-ai.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
