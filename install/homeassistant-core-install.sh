#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.home-assistant.io/

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
  gnupg \
  ca-certificates \
  bluez \
  libtiff6 \
  tzdata \
  libffi-dev \
  libssl-dev \
  libjpeg-dev \
  zlib1g-dev \
  autoconf \
  build-essential \
  libopenjp2-7 \
  libturbojpeg0-dev \
  ffmpeg \
  liblapack3 \
  liblapack-dev \
  dbus-broker \
  libpcap-dev \
  libavdevice-dev \
  libavformat-dev \
  libavcodec-dev \
  libavutil-dev \
  libavfilter-dev \
  libmariadb-dev-compat \
  libatlas-base-dev \
  software-properties-common \
  libmariadb-dev \
  pkg-config
msg_ok "Installed Dependencies"

setup_uv
msg_info "Setup Python3"
$STD apt-get install -y \
  python3.13 \
  python3.13-dev \
  python3.13-venv
msg_ok "Setup Python3"

msg_info "Preparing Python 3.13 for uv"
$STD uv python install 3.13
UV_PYTHON=$(uv python list | awk '/3\.13\.[0-9]+.*\/root\/.local/ {print $2; exit}')
if [[ -z "$UV_PYTHON" ]]; then
  msg_error "No local Python 3.13 found via uv"
  exit 1
fi
msg_ok "Prepared Python 3.13"

msg_info "Setting up Home Assistant-Core environment"
rm -rf /srv/homeassistant
mkdir -p /srv/homeassistant
cd /srv/homeassistant
$STD uv venv .venv --python "$UV_PYTHON"
source .venv/bin/activate
msg_ok "Created virtual environment"

msg_info "Installing Home Assistant-Core"
$STD uv pip install homeassistant mysqlclient psycopg2-binary isal webrtcvad wheel
mkdir -p /root/.homeassistant
msg_ok "Installed Home Assistant-Core"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/root/.homeassistant
Environment="PATH=/srv/homeassistant/.venv/bin:/usr/local/bin:/usr/bin"
ExecStart=/srv/homeassistant/.venv/bin/python3 -m homeassistant --config /root/.homeassistant
Restart=always
RestartForceExitStatus=100

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now homeassistant
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
