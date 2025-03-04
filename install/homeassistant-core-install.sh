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
  curl \
  git \
  sudo \
  mc \
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

msg_info "Setup Python3"
$STD apt-get update
$STD rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD apt-get remove --purge -y python3.12 python3.12-dev python3.12-venv

$STD apt-get install -y \
  python3.13 \
  python3-pip \
  python3.13-dev \
  python3.13-venv

ln -sf /usr/bin/python3.13 /usr/bin/python3
msg_ok "Setup Python3"

msg_info "Setting up Home Assistant-Core environment"
mkdir /srv/homeassistant
cd /srv/homeassistant
python3 -m venv .
source bin/activate
msg_ok "Created virtual environment"

msg_info "Installing Home Assistant-Core"
$STD python3 -m pip install webrtcvad wheel homeassistant mysqlclient psycopg2-binary isal
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
Environment="PATH=/srv/homeassistant/bin:/usr/local/bin:/usr/bin:/usr/local/bin/uv"
ExecStart=/srv/homeassistant/bin/python3 -m homeassistant --config /root/.homeassistant
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