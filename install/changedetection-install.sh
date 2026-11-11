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

wait_http() {
  local -r url="$1" timeout="${2:-30}"
  local -r deadline=$((SECONDS + timeout))
  local code
  while ((SECONDS < deadline)); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null)" || code="000"
    [[ "$code" =~ ^([23][0-9][0-9]|401|403)$ ]] && return 0
    sleep 2
  done
  return 1
}

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
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
  libgdk-pixbuf-2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  qpdf \
  xdg-utils \
  xvfb \
  xauth \
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

# sockpuppet runs as the non-root chrome user, so uv's Python must live outside /root (mode 700).
export UV_PYTHON_INSTALL_DIR=/opt/uv-python
PYTHON_VERSION="3.13" setup_uv

msg_info "Installing Change Detection"
mkdir -p /opt/changedetection
$STD uv venv --clear /opt/changedetection/.venv
$STD /opt/changedetection/.venv/bin/python -m ensurepip --upgrade
$STD /opt/changedetection/.venv/bin/python -m pip install --upgrade pip
$STD /opt/changedetection/.venv/bin/python -m pip install changedetection.io playwright
cat <<EOF >/opt/changedetection/.env
PLAYWRIGHT_DRIVER_URL=ws://127.0.0.1:3000/?headful=true&--window-size=1920,1080
LC_ALL=en_US.UTF-8
EOF
msg_ok "Installed Change Detection"

msg_info "Installing Chrome"
setup_deb822_repo "google-chrome" \
  "https://dl.google.com/linux/linux_signing_key.pub" \
  "https://dl.google.com/linux/chrome/deb/" "stable"
$STD apt install -y google-chrome-stable
msg_ok "Installed Chrome"

msg_info "Creating Chrome User"
groupadd -f chrome 2>/dev/null || true
id -u chrome >/dev/null 2>&1 || useradd --system --create-home --shell /usr/sbin/nologin -g chrome chrome
msg_ok "Created Chrome User"

fetch_and_deploy_gh_branch "sockpuppet" "dgtlmoon/sockpuppetbrowser" "master"
$STD uv venv --python 3.12 /opt/sockpuppet/.venv
$STD uv pip install --python /opt/sockpuppet/.venv/bin/python -r /opt/sockpuppet/requirements.txt

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

msg_info "Installing X11 Packages"
$STD apt install -y \
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
After=network.target sockpuppet.service
Wants=sockpuppet.service

[Service]
Type=simple
EnvironmentFile=/opt/changedetection/.env
WorkingDirectory=/opt/changedetection
ExecStart=/opt/changedetection/.venv/bin/changedetection.io -d /opt/changedetection -p 5000

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/sockpuppet.service
[Unit]
Description=sockpuppetbrowser service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=chrome
Group=chrome
WorkingDirectory=/opt/sockpuppet/backend
Environment=CHROME_BIN=/usr/bin/google-chrome-stable
Environment=CHROME_HEADFUL=true
Environment=PYTHONDONTWRITEBYTECODE=1
ExecStart=/opt/sockpuppet/.venv/bin/python server.py --host 127.0.0.1 --port 3000 --sport 8080
Restart=on-failure
RestartSec=5
SyslogIdentifier=sockpuppet

[Install]
WantedBy=default.target
EOF
systemctl enable -q --now sockpuppet
systemctl enable -q --now changedetection
msg_ok "Created Services"

msg_info "Verifying Sockpuppet"
if ! wait_http "http://127.0.0.1:8080/stats" 30 ||
  ! curl -sS --max-time 5 "http://127.0.0.1:8080/stats" | grep -qE '"chrome_version":[[:space:]]*"Google Chrome'; then
  msg_error "Sockpuppet failed to start"
  systemctl status sockpuppet --no-pager -l | head -20 || true
  exit 1
fi
msg_ok "Verified Sockpuppet"

msg_info "Verifying Change Detection"
if ! wait_http "http://127.0.0.1:5000/" 30; then
  msg_error "Change Detection is not responding"
  systemctl status changedetection --no-pager -l | head -20 || true
  exit 1
fi
msg_ok "Verified Change Detection"

motd_ssh
customize
cleanup_lxc
