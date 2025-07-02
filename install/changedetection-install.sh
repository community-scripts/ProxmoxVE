#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/

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
  ca-certificates
msg_ok "Installed Dependencies"

msg_info "Setup Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Setup Python3"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Change Detection"
mkdir /opt/changedetection
$STD pip3 install changedetection.io
msg_ok "Installed Change Detection"

msg_info "Installing Browserless & Playwright"
mkdir /opt/browserless
$STD python3 -m pip install playwright
$STD git clone https://github.com/browserless/chrome /opt/browserless
$STD npm install --prefix /opt/browserless
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

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/changedetection.service
[Unit]
Description=Change Detection
After=network-online.target
After=network.target browserless.service
Wants=browserless.service
[Service]
Type=simple
WorkingDirectory=/opt/changedetection
Environment=WEBDRIVER_URL=http://127.0.0.1:4444/wd/hub
Environment=PLAYWRIGHT_DRIVER_URL=ws://localhost:3000/chrome?launch=eyJkZWZhdWx0Vmlld3BvcnQiOnsiaGVpZ2h0Ijo3MjAsIndpZHRoIjoxMjgwfSwiaGVhZGxlc3MiOmZhbHNlLCJzdGVhbHRoIjp0cnVlfQ==&blockAds=true
ExecStart=changedetection.io -d /opt/changedetection -p 5000
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/browserless.service
[Unit]
Description=browserless service
After=network.target
[Service]
Environment=CONNECTION_TIMEOUT=60000
WorkingDirectory=/opt/browserless
ExecStart=/opt/browserless/scripts/start.sh
SyslogIdentifier=browserless
[Install]
WantedBy=default.target
EOF

systemctl enable -q --now browserless
systemctl enable -q --now changedetection
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
