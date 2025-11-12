#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: havardthom | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwebui.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Open WebUI"
$STD uv tool install --python 3.12 open-webui[all]
msg_ok "Installed Open WebUI"

read -r -p "${TAB3}Would you like to add Ollama? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Ollama"
  curl -fsSLO -C - https://ollama.com/download/ollama-linux-amd64.tgz
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
  systemctl enable -q --now ollama
  echo "ENABLE_OLLAMA_API=true" >/root/.env
  msg_ok "Installed Ollama"
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
Type=simple
EnvironmentFile=-/root/.env
Environment=DATA_DIR=/root/.open-webui
ExecStart=/root/.local/bin/open-webui serve
WorkingDirectory=/root
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now open-webui
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
