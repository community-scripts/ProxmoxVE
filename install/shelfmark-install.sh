#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/calibrain/shelfmark

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  unrar-free
ln -sf /usr/bin/unrar-free /usr/bin/unrar
msg_ok "Installed Dependencies"

mkdir -p /etc/shelfmark
cat <<EOF >/etc/shelfmark/.env
DOCKERMODE=false
CONFIG_DIR=/etc/shelfmark
TMP_DIR=/tmp/shelfmark
ENABLE_LOGGING=true
FLASK_HOST=0.0.0.0
FLASK_PORT=8084
# SESSION_COOKIES_SECURE=true
# CWA_DB_PATH=
USE_CF_BYPASS=true
USING_EXTERNAL_BYPASSER=false
# EXT_BYPASSER_URL=
# EXT_BYPASSER_PATH=/v1
EOF

echo ""
echo ""
echo -e "${BL}Shelfmark Deployment Type${CL}"
echo "─────────────────────────────────────────"
echo "Please choose your deployment type:"
echo ""
echo " 1) Use Shelfmark's internal captcha bypasser (default)"
echo " 2) Install FlareSolverr in this LXC"
echo " 3) Use an existing Flaresolverr/Byparr LXC"
echo " 4) Disable captcha bypassing altogether (not recommended)"
echo ""

read -r -p "${TAB3}Select deployment type [1]: " DEPLOYMENT_TYPE
DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:-1}"

case "$DEPLOYMENT_TYPE" in
1)
  msg_ok "Using Shelfmark's internal captcha bypasser"
  ;;
2)
  msg_ok "Proceeding with FlareSolverr installation"
  ;;
3)
  echo ""
  echo -e "${BL}Use an existing FlareSolverr/Byparr LXC${CL}"
  echo "─────────────────────────────────────────"
  echo "Enter the URL/IP address with port of your Flaresolverr/Byparr instance"
  echo "Example: http://flaresoverr.homelab.lan:8191 or"
  echo "http://192.168.10.99:8191"
  echo ""
  read -r -p "FlareSolverr/Byparr URL: " BYPASSER_URL

  if [[ -z "$BYPASSER_URL" ]]; then
    msg_warn "No Flaresolverr/Byparr URL provided. Falling back to Shelfmark's internal bypasser."
  else
    BYPASSER_URL="${BYPASSER_URL%/}"
    msg_ok "FlareSolverr/Byparr URL: ${BYPASSER_URL}"
  fi
  ;;
4)
  msg_warn "Disabling captcha bypass. This may cause the majority of searches and downloads to fail."
  ;;
*)
  msg_warn "Invalid selection. Reverting to default (internal bypasser)!"
  ;;
esac

if [[ "$DEPLOYMENT_TYPE" == "2" ]]; then
  fetch_and_deploy_gh_release "flaresolverr" "FlareSolverr/FlareSolverr" "prebuild" "latest" "/opt/flaresolverr" "flaresolverr_linux_x64.tar.gz"
  msg_info "Installing FlareSolverr (patience)"
  $STD apt install -y xvfb
  setup_deb822_repo \
    "google-chrome" \
    "https://dl.google.com/linux/linux_signing_key.pub" \
    "https://dl.google.com/linux/chrome/deb/" \
    "stable"
  $STD apt install -y google-chrome-stable
  rm /etc/apt/sources.list.d/google-chrome.list
  sed -i -e '/BYPASSER=/s/false/true/' \
    -e 's/^# EXT_/EXT_/' \
    -e "s|_URL=.*|_URL=http://localhost:8191|" /etc/shelfmark/.env
  msg_ok "Installed FlareSolverr"
elif [[ "$DEPLOYMENT_TYPE" == "3" ]]; then
  sed -i -e '/BYPASSER=/s/false/true/' \
    -e 's/^# EXT_/EXT_/' \
    -e "s|_URL=.*|_URL=${BYPASSER_URL}|" /etc/shelfmark/.env
elif [[ "$DEPLOYMENT_TYPE" == "4" ]]; then
  sed -i '/_BYPASS=/s/true/false/' /etc/shelfmark/.env
else
  DEPLOYMENT_TYPE="1"
  CHROME_VERSION=$(curl -fsSL https://raw.githubusercontent.com/calibrain/shelfmark/refs/heads/main/Dockerfile | sed -n '/chromium=/s/[^=]*=//p' | awk '{print $1}')
  msg_info "Installing internal bypasser dependencies"
  $STD apt install -y --no-install-recommends \
    xvfb \
    ffmpeg \
    chromium-common=${CHROME_VERSION} \
    chromium=${CHROME_VERSION} \
    chromium-driver=${CHROME_VERSION} \
    python3-tk
  msg_ok "Installed internal bypasser dependencies"
fi

NODE_VERSION="22" setup_nodejs
PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "shelfmark" "calibrain/shelfmark" "tarball" "latest" "/opt/shelfmark"
RELEASE_VERSION=$(cat "$HOME/.shelfmark")

msg_info "Building Shelfmark frontend"
cd /opt/shelfmark/src/frontend
echo "RELEASE_VERSION=${RELEASE_VERSION}" >>/etc/shelfmark/.env
$STD npm ci
$STD npm run build
mv /opt/shelfmark/src/frontend/dist /opt/shelfmark/frontend-dist
msg_ok "Built Shelfmark frontend"

msg_info "Configuring Shelfmark"
cd /opt/shelfmark
$STD uv venv ./venv
$STD source ./venv/bin/activate
$STD uv pip install -r ./requirements-base.txt
[[ "$DEPLOYMENT_TYPE" == "1" ]] && $STD uv pip install -r ./requirements-shelfmark.txt
mkdir -p {/var/log/shelfmark,/tmp/shelfmark}
msg_ok "Configured Shelfmark"

msg_info "Creating Services and start script"
cat <<EOF >/etc/systemd/system/shelfmark.service
[Unit]
Description=Shelfmark server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/shelfmark
EnvironmentFile=/etc/shelfmark/.env
ExecStart=/usr/bin/bash /opt/shelfmark/start.sh
Restart=always
RestartSec=10
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

if [[ "$DEPLOYMENT_TYPE" == "1" ]]; then
  cat <<EOF >/etc/systemd/system/chromium.service
[Unit]
Description=Chromium Headless Browser
After=network.target

[Service]
User=root
ExecStart=/usr/bin/chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --hide-scrollbars
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now chromium
fi
if [[ "$DEPLOYMENT_TYPE" == "2" ]]; then
  cat <<EOF >/etc/systemd/system/flaresolverr.service
[Unit]
Description=FlareSolverr
After=network.target
[Service]
SyslogIdentifier=flaresolverr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
WorkingDirectory=/opt/flaresolverr
ExecStart=/opt/flaresolverr/flaresolverr
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now flaresolverr
fi

cat <<EOF >/opt/shelfmark/start.sh
#!/usr/bin/env bash

source /opt/shelfmark/venv/bin/activate
set -a
source /etc/shelfmark/.env
set +a

gunicorn --worker-class geventwebsocket.gunicorn.workers.GeventWebSocketWorker --workers 1 -t 300 -b 0.0.0.0:8084 shelfmark.main:app
EOF
chmod +x /opt/shelfmark/start.sh

systemctl enable -q --now shelfmark
msg_ok "Created Services and start script"

motd_ssh
customize
cleanup_lxc
