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
  python3-pip
msg_ok "Installed Dependencies"

# pip install uv
# uv venv --python 3.12
PYTHON_VERSION="3.12" setup_uv
uv python update-shell

NODE_VERSION="24" setup_nodejs

#apt install chromium

# msg_info "Installing Browserless & Playwright"
# mkdir /opt/browserless
# $STD python3 -m pip install playwright
# $STD git clone https://github.com/browserless/chrome /opt/browserless
# $STD npm ci --include=optional --include=dev --prefix /opt/browserless
# $STD /opt/browserless/node_modules/playwright-core/cli.js install --with-deps &>/dev/null
# $STD /opt/browserless/node_modules/playwright-core/cli.js install --force chrome &>/dev/null
# $STD /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit &>/dev/null
# $STD /opt/browserless/node_modules/playwright-core/cli.js install --force msedge
# $STD npm run build --prefix /opt/browserless
# $STD npm run build:function --prefix /opt/browserless
# $STD npm prune production --prefix /opt/browserless
# msg_ok "Installed Browserless & Playwright"

# msg_info "Installing Font Packages"
# $STD apt-get install -y \
  # fontconfig \
  # libfontconfig1 \
  # fonts-freefont-ttf \
  # fonts-gfs-neohellenic \
  # fonts-indic fonts-ipafont-gothic \
  # fonts-kacst fonts-liberation \
  # fonts-noto-cjk \
  # fonts-noto-color-emoji \
  # msttcorefonts \
  # fonts-roboto \
  # fonts-thai-tlwg \
  # fonts-wqy-zenhei
# msg_ok "Installed Font Packages"

# msg_info "Installing X11 Packages"
# $STD apt-get install -y \
  # libx11-6 \
  # libx11-xcb1 \
  # libxcb1 \
  # libxcomposite1 \
  # libxcursor1 \
  # libxdamage1 \
  # libxext6 \
  # libxfixes3 \
  # libxi6 \
  # libxrandr2 \
  # libxrender1 \
  # libxss1 \
  # libxtst6
# msg_ok "Installed X11 Packages"

# msg_info "Downloading browser-use source"
# fetch_and_deploy_gh_release "browser-use" "browser-use/browser-use" "tarball" "latest" "/opt/browser-use"
# msg_ok "Downloaded browser-use source"

msg_info "Installing browser-use"

mkdir -p /etc/browser-use
cd /etc/browser-use
wget -qO .env https://raw.githubusercontent.com/browser-use/browser-use/refs/heads/main/.env.example

echo "BROWSER_USE_HEADLESS=true" >> /etc/browser-use/.env
echo "OPENAI_API_KEY=your-key-here" >> /etc/browser-use/.env




# User config
BROWSERUSE_USER="browseruse"
DEFAULT_PUID=911
DEFAULT_PGID=911

mkdir -p /opt/browser-use
# Paths
CODE_DIR=/opt/browser-use
DATA_DIR=/data
VENV_DIR=/opt/browser-use/.venv
#PATH="/app/.venv/bin:$PATH"


# Create non-privileged user for browseruse and chrome
echo "[*] Setting up $BROWSERUSE_USER user uid=${DEFAULT_PUID}..."
groupadd --system $BROWSERUSE_USER
useradd --system --create-home --gid $BROWSERUSE_USER --groups audio,video $BROWSERUSE_USER
usermod -u "$DEFAULT_PUID" "$BROWSERUSE_USER"
groupmod -g "$DEFAULT_PGID" "$BROWSERUSE_USER"
mkdir -p $DATA_DIR
mkdir -p /home/$BROWSERUSE_USER/.config
chown -R $BROWSERUSE_USER:$BROWSERUSE_USER /home/$BROWSERUSE_USER
ln -s $DATA_DIR /home/$BROWSERUSE_USER/.config/browseruse
#echo -e "\nBROWSERUSE_USER=$BROWSERUSE_USER PUID=$(id -u $BROWSERUSE_USER) PGID=$(id -g $BROWSERUSE_USER)\n\n" | tee -a /VERSION.txt
# DEFAULT_PUID and DEFAULT_PID are overridden by PUID and PGID in /bin/docker_entrypoint.sh at runtime
# https://docs.linuxserver.io/general/understanding-puid-and-pgid


# Install base apt dependencies (adding backports to access more recent apt updates)
echo "[+] Installing APT base system dependencies for $TARGETPLATFORM..."
#     && echo 'deb https://deb.debian.org/debian bookworm-backports main contrib non-free' > /etc/apt/sources.list.d/backports.list \
mkdir -p /etc/apt/keyrings
apt-get update -qq
apt-get install -qq -y --no-install-recommends apt-transport-https ca-certificates apt-utils gnupg2 unzip curl wget grep nano iputils-ping dnsutils jq
rm -rf /var/lib/apt/lists/*



#Should already be setup
#pip install uv

# Install Chromium browser directly from system packages
echo "[+] Installing chromium browser from system packages..."
apt-get update -qq
apt-get install -y --no-install-recommends \
        chromium \
        fonts-unifont \
        fonts-liberation \
        fonts-dejavu-core \
        fonts-freefont-ttf \
        fonts-noto-core
rm -rf /var/lib/apt/lists/*
ln -s /usr/bin/chromium /usr/bin/chromium-browser
ln -s /usr/bin/chromium /$CODE_DIR/chromium-browser
mkdir -p "/home/${BROWSERUSE_USER}/.config/chromium/Crash Reports/pending/"
chown -R "$BROWSERUSE_USER:$BROWSERUSE_USER" "/home/${BROWSERUSE_USER}/.config"
# ( \
    # which chromium-browser && /usr/bin/chromium-browser --version \
    # && echo -e '\n\n' \
# ) | tee -a /VERSION.txt


uv sync --all-extras --no-dev --no-install-project

# Copy the rest of the browser-use codebase
#COPY . /app
uv pip install browser-use
uvx browser-use install

# Install the browser-use package and all of its optional dependencies
#RUN --mount=type=cache,target=/root/.cache,sharing=locked,id=cache-$TARGETARCH$TARGETVARIANT \
echo "[+] Installing browser-use pip library from source..."
uv sync --all-extras --locked --no-dev
python -c "import browser_use; print('browser-use installed successfully')"


RUN mkdir -p "$DATA_DIR/profiles/default"
chown -R $BROWSERUSE_USER:$BROWSERUSE_USER "$DATA_DIR" "$DATA_DIR"/*
    # && ( \
        # echo -e "\n\n[√] Finished Docker build successfully. Saving build summary in: /VERSION.txt" \
        # && echo -e "PLATFORM=${TARGETPLATFORM} ARCH=$(uname -m) ($(uname -s) ${TARGETARCH} ${TARGETVARIANT})\n" \
        # && echo -e "BUILD_END_TIME=$(date +"%Y-%m-%d %H:%M:%S %s")\n\n" \
    # ) | tee -a /VERSION.txt











#########MANUAL INSTALL
# pip install uv
# #uv venv --python 3.12
# #source .venv/bin/activate
# uv pip install browser-use
# uvx browser-use install

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

mkdir -p /opt/browser-use
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
	browser_profile=browser_profile,
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