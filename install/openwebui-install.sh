#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gpg
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Installing Python3 Dependencies"
$STD apt-get install -y --no-install-recommends \
  python3 \
  python3-pip
msg_ok "Installed Python3 Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing Open WebUI (Patience)"
$STD git clone https://github.com/open-webui/open-webui.git /opt/open-webui
cd /opt/open-webui/backend
$STD pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
$STD pip3 install -r requirements.txt -U
cd /opt/open-webui
cp .env.example .env
cat <<EOF >/opt/open-webui/.env
ENV=prod
ENABLE_OLLAMA_API=false
OLLAMA_BASE_URL=http://0.0.0.0:11434
EOF
$STD npm install
export NODE_OPTIONS="--max-old-space-size=3584"
$STD npm run build
msg_ok "Installed Open WebUI"

read -r -p "Would you like to add Ollama? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Ollama"
  curl -fsSLO https://ollama.com/download/ollama-linux-amd64.tgz
  tar -C /usr -xzf ollama-linux-amd64.tgz
  rm -rf ollama-linux-amd64.tgz
  cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
Type=exec
ExecStart=/usr/bin/ollama serve
Environment=HOME=$HOME
Environment=OLLAMA_HOST=0.0.0.0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now ollama.service
  sed -i 's/ENABLE_OLLAMA_API=false/ENABLE_OLLAMA_API=true/g' /opt/open-webui/.env
  msg_ok "Installed Ollama"
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/open-webui
EnvironmentFile=/opt/open-webui/.env
ExecStart=/opt/open-webui/backend/start.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now open-webui.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
