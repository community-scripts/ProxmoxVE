#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: davalanche | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mylar3/mylar3

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
cat <<EOF >/etc/apt/sources.list.d/non-free.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: bookworm
Components: non-free non-free-firmware
EOF
$STD apt update
$STD apt install -y unrar
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "mylar3" "mylar3/mylar3" "tarball"

msg_info "Installing ${APPLICATION}"
mkdir -p /opt/mylar3-data
$STD uv venv /opt/mylar3/.venv
$STD /opt/mylar3/.venv/bin/python -m ensurepip --upgrade
$STD /opt/mylar3/.venv/bin/python -m pip install --upgrade pip
$STD /opt/mylar3/.venv/bin/python -m pip install --no-cache-dir -r /opt/mylar3/requirements.txt
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mylar3.service
[Unit]
Description=Mylar3 Service
After=network-online.target

[Service]
ExecStart=/opt/mylar3/.venv/bin/python /opt/mylar3/Mylar.py --daemon --nolaunch --datadir=/opt/mylar3-data
GuessMainPID=no
Type=forking
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mylar3
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
