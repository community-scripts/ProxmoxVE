#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/searxng/searxng

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing SearXNG dependencies"
echo "deb http://deb.debian.org/debian bookworm-backports main" > /etc/apt/sources.list.d/backports.list
$STD apt-get update
$STD apt-get install -y \
  python3-dev python3-babel python3-venv python-is-python3 \
  uwsgi uwsgi-plugin-python3 \
  git build-essential libxslt-dev zlib1g-dev libffi-dev libssl-dev sudo valkey
msg_ok "Installed dependencies"

msg_info "Creating user and preparing directories"
useradd --system --shell /bin/bash --home-dir "/usr/local/searxng" --comment 'Privacy-respecting metasearch engine' searxng || true
mkdir -p /usr/local/searxng
chown -R searxng:searxng /usr/local/searxng
msg_ok "User and directories ready"

msg_info "Cloning SearXNG source"
$STD sudo -H -u searxng git clone https://github.com/searxng/searxng /usr/local/searxng/searxng-src
msg_ok "Cloned SearXNG"

msg_info "Creating Python virtual environment"
sudo -H -u searxng bash -c '
  python3 -m venv /usr/local/searxng/searx-pyenv &&
  . /usr/local/searxng/searx-pyenv/bin/activate &&
  pip install -U pip setuptools wheel pyyaml &&
  pip install --use-pep517 --no-build-isolation -e /usr/local/searxng/searxng-src
'
msg_ok "Python environment ready"

msg_info "Configuring SearXNG settings"
mkdir -p /etc/searxng
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
  limiter: false
  image_proxy: true
valkey:
  url: "valkey://localhost:6379/0"
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
msg_ok "Configured settings"

msg_info "Set up web services"
cat <<EOF >/etc/systemd/system/searxng.service
[Unit]
Description=SearXNG service
After=network.target valkey-server.service
Wants=valkey-server.service

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
