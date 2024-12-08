#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
     curl \
     sudo \
     mc \
     bluez \
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
     pip \
     software-properties-common
$STD add-apt-repository -y ppa:deadsnakes/ppa
$STD apt-get update
$STD apt-get install -y python3.13-dev
msg_ok "Installed Dependencies"

msg_info "Installing UV"
$STD pip install uv
msg_ok "Installing UV"

msg_info "Setup Home Assistant-Core"
mkdir /srv/homeassistant
cd /srv/homeassistant
uv venv . &>/dev/null
source bin/activate
msg_ok "Setup Home Assistant-Core"

msg_info "Setup Home Assistant-Core Packages"
$STD uv pip install webrtcvad wheel homeassistant mysqlclient psycopg2-binary isal
mkdir -p /root/.homeassistant
msg_ok "Setup Home Assistant-Core Packages"

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
msg_ok "Creating Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaning up"
