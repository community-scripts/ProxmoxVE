#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lissy93/web-check

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
export DEBIAN_FRONTEND=noninteractive
$STD apt-get -y install --no-install-recommends \
  git \
  traceroute \
  make \
  g++ \
  traceroute \
  xvfb \
  dbus \
  xorg \
  xvfb \
  gtk2-engines-pixbuf \
  dbus-x11 \
  xfonts-base \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  imagemagick \
  x11-apps
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Setup Python3"
$STD apt-get install -y python3
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Setup Python3"

msg_info "Installing Chromium"
curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/trusted.gpg.d/google-archive.gpg
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >/etc/apt/sources.list.d/google.list
$STD apt-get update
$STD apt-get -y install \
  chromium \
  libxss1 \
  lsb-release
msg_ok "Installed Chromium"

msg_info "Setting up Chromium"
/usr/bin/chromium --no-sandbox --version >/etc/chromium-version
chmod 755 /usr/bin/chromium
msg_ok "Setup Chromium"

msg_info "Installing Web-Check (Patience)"
temp_file=$(mktemp)
RELEASE="patch-1"
curl -fsSL "https://github.com/CrazyWolf13/web-check/archive/refs/heads/${RELEASE}.tar.gz" -o "$temp_file"
tar xzf $temp_file
mv web-check-${RELEASE} /opt/web-check
cd /opt/web-check
cat <<'EOF' >/opt/web-check/.env
CHROME_PATH=/usr/bin/chromium
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
HEADLESS=true
GOOGLE_CLOUD_API_KEY=''
REACT_APP_SHODAN_API_KEY=''
REACT_APP_WHO_API_KEY=''
SECURITY_TRAILS_API_KEY=''
CLOUDMERSIVE_API_KEY=''
TRANCO_USERNAME=''
TRANCO_API_KEY=''
URL_SCAN_API_KEY=''
BUILT_WITH_API_KEY=''
TORRENT_IP_API_KEY=''
PORT='3000'
DISABLE_GUI='false'
API_TIMEOUT_LIMIT='10000'
API_CORS_ORIGIN='*'
API_ENABLE_RATE_LIMIT='false'
REACT_APP_API_ENDPOINT='/api'
ENABLE_ANALYTICS='false'
EOF
$STD yarn install --frozen-lockfile --network-timeout 100000
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Web-Check"

msg_info "Building Web-Check"
$STD yarn build --production
msg_ok "Built Web-Check"

msg_info "Creating Service"
cat <<'EOF' >/opt/run_web-check.sh
#!/bin/bash
SCREEN_RESOLUTION="1280x1024x24"
if ! systemctl is-active --quiet dbus; then
  echo "Warning: dbus service is not running. Some features may not work properly."
fi
[[ -z "${DISPLAY}" ]] && export DISPLAY=":99"
Xvfb "${DISPLAY}" -screen 0 "${SCREEN_RESOLUTION}" &
XVFB_PID=$!
sleep 2
cd /opt/web-check
exec yarn start
EOF
chmod +x /opt/run_web-check.sh
cat <<'EOF' >/etc/systemd/system/web-check.service
[Unit]
Description=Web Check Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/web-check
EnvironmentFile=/opt/web-check/.env
ExecStartPre=/bin/bash -c "service dbus start || true"
ExecStartPre=/bin/bash -c "if ! pgrep -f 'Xvfb.*:99' > /dev/null; then Xvfb :99 -screen 0 1280x1024x24 & fi"
ExecStart=/opt/run_web-check.sh
Restart=on-failure
Environment=DISPLAY=:99

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now web-check
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $temp_file
rm -rf /var/lib/apt/lists/* /app/node_modules/.cache
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
