#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/searxng/searxng

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  redis-server \
  build-essential \
  libffi-dev \
  libssl-dev \
  curl \
  sudo \
  git \
  mc
msg_ok "Installed Dependencies"

msg_info "Setup Python3" 
$STD apt-get install -y \
  python3 \
  python3-{pip,venv,yaml,dev} 
$STD pip install --upgrade pip setuptools wheel 
$STD pip install pyyaml
msg_ok "Setup Python3"

msg_info "Setup SearXNG"
mkdir -p /usr/local/searxng /etc/searxng
useradd -d /etc/searxng searxng
chown searxng:searxng /usr/local/searxng /etc/searxng
$STD git clone https://github.com/searxng/searxng.git /usr/local/searxng/searxng-src
cd /usr/local/searxng/
sudo -u searxng python3 -m venv /usr/local/searxng/searx-pyenv
source /usr/local/searxng/searx-pyenv/bin/activate
$STD pip install --upgrade pip setuptools wheel 
$STD pip install pyyaml
$STD pip install -e /usr/local/searxng/searxng-src
SECRET_KEY=$(openssl rand -hex 32)
cat <<EOF >/etc/searxng/settings.yml
# SearXNG settings
use_default_settings: true
general:
  debug: false
  instance_name: "SearXNG"
  privacypolicy_url: false
  contact_url: false
server:
  bind_address: "0.0.0.0"
  port: 8888
  secret_key: "${SECRET_KEY}"
  limiter: true
  image_proxy: true
redis:
  url: "redis://127.0.0.1:6379/0"
ui:
  static_use_hash: true
enabled_plugins:
  - 'Hash plugin'
  - 'Self Information'
  - 'Tracker URL remover'
  - 'Ahmia blacklist'
search:
  safe_search: 2
  autocomplete: 'google'
engines:
  - name: google
    engine: google
    shortcut: gg
    use_mobile_ui: false
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
    display_error_messages: true
EOF
chown searxng:searxng /etc/searxng/settings.yml
chmod 640 /etc/searxng/settings.yml
msg_ok "Setup SearXNG"

msg_info "Set up web services"
cat <<EOF >/etc/systemd/system/searxng.service
[Unit]
Description=SearXNG service
After=network.target redis-server.service
Wants=redis-server.service

[Service]
Type=simple
User=searxng
Group=searxng
Environment="SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
ExecStart=/usr/local/searxng/searx-pyenv/bin/python -m searx.webapp
WorkingDirectory=/usr/local/searxng/searxng-src
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now searxng
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
