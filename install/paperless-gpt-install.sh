#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/icereed/paperless-gpt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  gcc \
  ca-certificates \
  musl-dev \
  mupdf \
  libc6-dev \
  musl-tools
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
setup_go

msg_info "Setup Paperless-GPT"
temp_file=$(mktemp)
RELEASE=$(curl -fsSL https://api.github.com/repos/icereed/paperless-gpt/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/icereed/paperless-gpt/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar zxf "$temp_file"
mv paperless-gpt-"${RELEASE}" /opt/paperless-gpt
cd /opt/paperless-gpt/web-app
$STD npm install
$STD npm run build
cd /opt/paperless-gpt
go mod download
export CC=musl-gcc
CGO_ENABLED=1 go build -tags musl -o /dev/null github.com/mattn/go-sqlite3
CGO_ENABLED=1 go build -tags musl -o paperless-gpt .
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Paperless-GPT"

mkdir -p /opt/paperless-gpt-data
read -p "${TAB3}Do you want to enter the Paperless local URL now? (y/n) " input_url
if [[ "$input_url" =~ ^[Yy]$ ]]; then
  read -p "${TAB3}Enter your Paperless-NGX instance URL (e.g., http://192.168.1.100:8000): " PAPERLESS_BASE_URL
else
  PAPERLESS_BASE_URL="http://your_paperless_ngx_url"
fi

read -p "${TAB3}Do you want to enter the Paperless API token now? (y/n) " input_token
if [[ "$input_token" =~ ^[Yy]$ ]]; then
  read -p "${TAB3}Enter your Paperless API token: " PAPERLESS_API_TOKEN
else
  PAPERLESS_API_TOKEN="your_paperless_api_token"
fi

msg_info "Setup Environment"
cat <<EOF >/opt/paperless-gpt-data/.env
PAPERLESS_BASE_URL=$PAPERLESS_BASE_URL
PAPERLESS_API_TOKEN=$PAPERLESS_API_TOKEN

LLM_PROVIDER=openai
LLM_MODEL=gpt-4o
OPENAI_API_KEY=your_openai_api_key

#VISION_LLM_PROVIDER=ollama
#VISION_LLM_MODEL=minicpm-v

LLM_LANGUAGE=English
LOG_LEVEL=info

LISTEN_INTERFACE=:8080

AUTO_TAG=paperless-gpt-auto
MANUAL_TAG=paperless-gpt
AUTO_OCR_TAG=paperless-gpt-ocr-auto

OCR_LIMIT_PAGES=5
EOF
msg_ok "Setup Environment"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/paperless-gpt.service
[Unit]
Description=Paperless-GPT
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/paperless-gpt
ExecStart=/opt/paperless-gpt/paperless-gpt
Restart=always
User=root
EnvironmentFile=/opt/paperless-gpt-data/.env
StandardOutput=append:/var/log/paperless-gpt.log
StandardError=append:/var/log/paperless-gpt.log

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now paperless-gpt
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
