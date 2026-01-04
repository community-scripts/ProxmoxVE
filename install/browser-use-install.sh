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

#PYTHON_VERSION="3.12" USE_UVX="YES" setup_uv
USE_UVX="YES" setup_uv
uv python update-shell
#$STD update-alternatives --install /usr/bin/python3 python3 /root/.local/bin/python3.12 1

export DISPLAY=:99
echo "export DISPLAY=:99" >> ~/.bashrc

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y python3-pip
msg_ok "Installed Dependencies"

apt-get install -y --no-install-recommends \
    libnss3 \
    libnspr4 \
    libdbus-1-3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libxkbcommon0 \
    libasound2 \
    libatspi2.0-0 \
    xvfb \
    x11vnc \
    fontconfig
	
apt install chromium


pip install python-dotenv
pip install browser-use
pip install pytest-playwright
playwright install --with-deps

# OR:
# uv init
# #  We ship every day - use the latest version!
# uv add browser-use
# uv sync
# # .env
# BROWSER_USE_API_KEY=your-key
# cat <<EOF >.env
# OPENROUTER_API_KEY=xxxxxxxxxxxx
# EOF
# uvx browser-use install
# ####uvx playwright install



cat <<EOF >/etc/systemd/system/xvfb.service
[Unit]
Description=Xvfb service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=Xvfb :99 -ac -screen 0 1920x1080x24 -nolisten tcp

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now xvfb
sleep 3

cat <<EOF >/etc/systemd/system/x11vnc.service
[Unit]
Description=X11VNC service
After=network.target
After=xvfb.service

[Service]
Type=simple
Restart=always
RestartSec=1
#ExecStart=x11vnc -display :99 -rfbport 5900 -listen 0.0.0.0 -N -forever -shared -passwd secret
ExecStart=x11vnc -display :99 -rfbport 5900 -listen 0.0.0.0 -N -forever -shared

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now x11vnc
sleep 3

cat <<EOF >test.py
from browser_use import Agent, Browser, ChatOpenAI
import asyncio
import os

os.environ["ANONYMIZED_TELEMETRY"] = "False"

async def example():
    browser = Browser(
        # use_cloud=True,  # Uncomment to use a stealth browser on Browser Use Cloud
        chromium_sandbox='False',
    )

    llm = ChatOpenAI(
        # model='x-ai/grok-4',
        model='openai/gpt-5.1',
        base_url='https://openrouter.ai/api/v1',
        api_key=os.getenv('OPENROUTER_API_KEY'),
    )

    agent = Agent(
        task="Find the number of stars of the browser-use repo",
        llm=llm,
        browser=browser,
    )

    history = await agent.run()
    return history

if __name__ == "__main__":
    history = asyncio.run(example())
EOF

motd_ssh
customize

msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"