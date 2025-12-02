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
$STD apt-get install -y \
  git \
  build-essential \
  dumb-init \
  gconf-service \
  libjpeg-dev \
  libatk-bridge2.0-0 \
  libasound2 \
  libatk1.0-0 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libgbm-dev \
  libgbm1 \
  libgconf-2-4 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  qpdf \
  xdg-utils \
  xvfb \
  ca-certificates \
  python3-pip
msg_ok "Installed Dependencies"

# pip install uv
# uv venv --python 3.12
PYTHON_VERSION="3.12" setup_uv
uv python update-shell

NODE_VERSION="24" setup_nodejs

#apt install chromium

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

msg_info "Installing Font Packages"
$STD apt-get install -y \
  fontconfig \
  libfontconfig1 \
  fonts-freefont-ttf \
  fonts-gfs-neohellenic \
  fonts-indic fonts-ipafont-gothic \
  fonts-kacst fonts-liberation \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  msttcorefonts \
  fonts-roboto \
  fonts-thai-tlwg \
  fonts-wqy-zenhei
msg_ok "Installed Font Packages"

msg_info "Installing X11 Packages"
$STD apt-get install -y \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6
msg_ok "Installed X11 Packages"

# msg_info "Downloading browser-use source"
# fetch_and_deploy_gh_release "browser-use" "browser-use/browser-use" "tarball" "latest" "/opt/browser-use"
# msg_ok "Downloaded browser-use source"

msg_info "Installing browser-use"

mkdir -p /etc/browser-use
cd /etc/browser-use
wget -qO .env https://raw.githubusercontent.com/browser-use/browser-use/refs/heads/main/.env.example

echo "BROWSER_USE_HEADLESS=true" >> /etc/browser-use/.env
echo "OPENAI_API_KEY=your-key-here" >> /etc/browser-use/.env


# mkdir -p /opt/browser-use
# cd /opt/browser-use
# $STD uv venv .venv
# #uv venv --python 3.12
# $STD source .venv/bin/activate
# $STD uv pip install --upgrade pip
# #$STD uv pip install --no-cache-dir -r requirements.txt
# uv pip install browser-use
# #uvx browser-use install
msg_ok "Installed browser-use"

cat <<EOF >/opt/browser-use/test.py
"""
Simple try of the agent.

@dev You need to add OPENAI_API_KEY to your environment variables.
"""

import asyncio
import os

from dotenv import load_dotenv

from browser_use import Agent, ChatOpenAI, Browser, BrowserProfile

load_dotenv()

browser_profile = BrowserProfile(
	headless=True,
)

# All the models are type safe from OpenAI in case you need a list of supported models
llm = ChatOpenAI(
	# model='x-ai/grok-4',
	model='openai/gpt-5.1',
	base_url='https://openrouter.ai/api/v1',
	api_key=os.getenv('OPENROUTER_API_KEY'),
)
agent = Agent(
	task='Find the number of stars of the browser-use repo',
	llm=llm,
	use_vision=False,
)


async def main():
	await agent.run(max_steps=10)


asyncio.run(main())
EOF

motd_ssh
customize

msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"