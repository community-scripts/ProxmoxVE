#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: CrazyWolf13, MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/ | Github: https://github.com/dgtlmoon/changedetection.io

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  qpdf \
  xvfb \
  xauth \
  python3 \
  locales \
  poppler-utils \
  file
msg_ok "Installed Dependencies"

msg_info "Generating Locales"
for l in cs_CZ de_DE en_GB en_US es_ES fr_FR id_ID it_IT ja_JP ko_KR \
  pl_PL pt_BR ru_RU tr_TR uk_UA zh_CN zh_TW; do
  sed -i "s/^# *${l}.UTF-8 UTF-8/${l}.UTF-8 UTF-8/" /etc/locale.gen
done
$STD locale-gen
msg_ok "Generated Locales"

PYTHON_VERSION="3.13" setup_uv

msg_info "Installing Change Detection"
mkdir -p /opt/changedetection
$STD uv venv --clear /opt/changedetection/.venv
$STD uv pip install --python /opt/changedetection/.venv/bin/python changedetection.io playwright
cat <<EOF >/opt/changedetection/.env
PLAYWRIGHT_DRIVER_URL=ws://127.0.0.1:3000/?headful=true&--window-size=1920,1080
LC_ALL=en_US.UTF-8
EOF
msg_ok "Installed Change Detection"

msg_info "Installing Chrome"
setup_deb822_repo \
  "google-chrome" \
  "https://dl.google.com/linux/linux_signing_key.pub" \
  "https://dl.google.com/linux/chrome/deb/" \
  "stable"
$STD apt install -y google-chrome-stable
rm -f /etc/apt/sources.list.d/google-chrome.list
msg_ok "Installed Chrome"

msg_info "Installing Font Packages"
$STD apt install -y \
  fontconfig \
  libfontconfig1 \
  fonts-freefont-ttf \
  fonts-gfs-neohellenic \
  fonts-indic fonts-ipafont-gothic \
  fonts-kacst-one fonts-liberation \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  fonts-roboto \
  fonts-thai-tlwg \
  fonts-wqy-zenhei
msg_ok "Installed Font Packages"

fetch_and_deploy_gh_release "sockpuppetbrowser" "dgtlmoon/sockpuppetbrowser" "tarball"

msg_info "Setting up SockPuppetBrowser"
useradd -r -m -s /usr/sbin/nologin chrome
$STD uv venv --clear --python /usr/bin/python3 /opt/sockpuppetbrowser/.venv
$STD uv pip install --python /opt/sockpuppetbrowser/.venv/bin/python -r /opt/sockpuppetbrowser/requirements.txt
msg_ok "Set up SockPuppetBrowser"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/sockpuppetbrowser.service
[Unit]
Description=SockPuppetBrowser
After=network.target

[Service]
User=chrome
Group=chrome
WorkingDirectory=/opt/sockpuppetbrowser/backend
Environment=CHROME_BIN=/usr/bin/google-chrome-stable
Environment=LOG_LEVEL=INFO
ExecStart=/opt/sockpuppetbrowser/.venv/bin/python server.py --host 127.0.0.1 --port 3000 --sport 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/changedetection.service
[Unit]
Description=Change Detection
After=network-online.target sockpuppetbrowser.service
Wants=sockpuppetbrowser.service

[Service]
Type=simple
EnvironmentFile=/opt/changedetection/.env
WorkingDirectory=/opt/changedetection
ExecStart=/opt/changedetection/.venv/bin/changedetection.io -d /opt/changedetection -p 5000

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sockpuppetbrowser changedetection
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
