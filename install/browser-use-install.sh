#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Authors: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://github.com/browser-use/browser-use

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
#$STD apt-get install -y {git,python3.13,python3.13-dev,python3.13-venv,python3-pip,build-essential,libpq5,libz-dev,libssl-dev,postgresql-client}
$STD apt install -y {python3-pip,git}
msg_ok "Installed Dependencies"

# pip install uv
# uv venv --python 3.12
PYTHON_VERSION="3.12" setup_uv
uv python update-shell

NODE_VERSION="24" setup_nodejs

msg_info "Installing Browserless & Playwright"
mkdir /opt/browserless
$STD python3 -m pip install playwright
$STD git clone https://github.com/browserless/chrome /opt/browserless
$STD npm ci --include=optional --include=dev --prefix /opt/browserless
$STD /opt/browserless/node_modules/playwright-core/cli.js install --with-deps &>/dev/null
$STD /opt/browserless/node_modules/playwright-core/cli.js install --force chrome &>/dev/null
$STD /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit &>/dev/null
$STD /opt/browserless/node_modules/playwright-core/cli.js install --force msedge
$STD npm run build --prefix /opt/browserless
$STD npm run build:function --prefix /opt/browserless
$STD npm prune production --prefix /opt/browserless
msg_ok "Installed Browserless & Playwright"

# msg_info "Downloading browser-use source"
# fetch_and_deploy_gh_release "browser-use" "browser-use/browser-use" "tarball" "latest" "/opt/browser-use"
# msg_ok "Downloaded browser-use source"

mkdir -p /etc/browser-use
cd /etc/browser-use
wget -qO .env https://raw.githubusercontent.com/browser-use/browser-use/refs/heads/main/.env.example

echo "BROWSER_USE_HEADLESS=true" >> /etc/browser-use/.env


msg_info "Installing browser-use"
mkdir -p /opt/browser-use
cd /opt/browser-use
$STD uv venv .venv
#uv venv --python 3.12
$STD source .venv/bin/activate
$STD uv pip install --upgrade pip
#$STD uv pip install --no-cache-dir -r requirements.txt
uv pip install browser-use
#uvx browser-use install
msg_ok "Installed browser-use"

motd_ssh
customize

msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"