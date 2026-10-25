#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ItzCrazyKns/Vane

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs
PYTHON_VERSION="3.13" setup_uv

fetch_and_deploy_gh_branch "searxng" "searxng/searxng" "master"

msg_info "Setting up SearXNG"
cd /opt/searxng
$STD uv venv /opt/searxng/.venv
$STD uv pip install -p /opt/searxng/.venv/bin/python -r requirements.txt -r requirements-server.txt
mkdir -p /etc/searxng
# Vane queries SearXNG with format=json and expects the Wolfram Alpha engine, like upstream's bundled instance
cat <<EOF >/etc/searxng/settings.yml
use_default_settings: true
general:
  instance_name: "SearXNG"
server:
  bind_address: "127.0.0.1"
  port: 8888
  secret_key: "$(openssl rand -hex 32)"
  limiter: false
  image_proxy: false
search:
  autocomplete: "google"
  formats:
    - html
    - json
engines:
  - name: wolframalpha
    disabled: false
EOF
chmod 600 /etc/searxng/settings.yml
msg_ok "Set up SearXNG"

fetch_and_deploy_gh_release "vane" "ItzCrazyKns/Vane" "tarball"

msg_info "Building Vane"
cd /opt/vane
$STD yarn install --frozen-lockfile --network-timeout 600000
$STD yarn build
$STD yarn cache clean
rm -rf .next/cache
cp -r public .next/standalone/
cp -r .next/static .next/standalone/.next/
cp -r drizzle .next/standalone/
mkdir -p /opt/vane_data
# The standalone server chdirs into its own directory and keeps config.json, db.sqlite and uploads in ./data
ln -s /opt/vane_data .next/standalone/data
msg_ok "Built Vane"

msg_info "Installing Chromium for Vane"
$STD npx playwright install --with-deps --only-shell chromium
msg_ok "Installed Chromium for Vane"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/searxng.service
[Unit]
Description=SearXNG for Vane
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/searxng
Environment=SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml
ExecStart=/opt/searxng/.venv/bin/granian --interface wsgi --host 127.0.0.1 --port 8888 searx.webapp:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/vane.service
[Unit]
Description=Vane
After=network.target searxng.service
Wants=searxng.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vane/.next/standalone
Environment=NODE_ENV=production
Environment=HOSTNAME=0.0.0.0
Environment=PORT=3000
Environment=SEARXNG_API_URL=http://127.0.0.1:8888
ExecStart=/usr/bin/node /opt/vane/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now searxng vane
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
