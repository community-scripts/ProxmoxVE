#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MountyMapleSyrup (MountyMapleSyrup)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/LazyLibrarian/LazyLibrarian

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  libpng-dev \
  libjpeg-dev \
  libtiff-dev \
  imagemagick
msg_ok "Installed Dependencies"

msg_info "Installing LazyLibrarian"
$STD git clone https://gitlab.com/LazyLibrarian/LazyLibrarian /opt/LazyLibrarian
cd /opt/LazyLibrarian
$STD uv venv /opt/LazyLibrarian/.venv
$STD /opt/LazyLibrarian/.venv/bin/python -m ensurepip --upgrade
$STD /opt/LazyLibrarian/.venv/bin/python -m pip install --upgrade pip
$STD /opt/LazyLibrarian/.venv/bin/python -m pip install . jaraco.stream python-Levenshtein soupsieve pypdf
msg_ok "Installed LazyLibrarian"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lazylibrarian.service
[Unit]
Description=LazyLibrarian Daemon
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/LazyLibrarian
ExecStart=/opt/LazyLibrarian/.venv/bin/python LazyLibrarian.py
UMask=0002
Restart=on-failure
TimeoutStopSec=20
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now lazylibrarian
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
