#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/motioneye-project/motioneye

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
$STD apt-get install -y cifs-utils
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Motion"
$STD apt-get install -y motion
systemctl stop motion
$STD systemctl disable motion
msg_ok "Installed Motion"

msg_info "Installing FFmpeg"
$STD apt-get install -y ffmpeg v4l-utils
msg_ok "Installed FFmpeg"

msg_info "Installing MotionEye"
$STD apt-get update
$STD uv venv /opt/motioneye/.venv
$STD /opt/motioneye/.venv/bin/python -m ensurepip --upgrade
$STD /opt/motioneye/.venv/bin/python -m pip install --upgrade pip
$STD /opt/motioneye/.venv/bin/python -m pip install --pre motioneye

mkdir -p /etc/motioneye
chown -R root:root /etc/motioneye
chmod -R 777 /etc/motioneye
curl -fsSL "https://raw.githubusercontent.com/motioneye-project/motioneye/dev/motioneye/extra/motioneye.conf.sample" -o "/etc/motioneye/motioneye.conf"
mkdir -p /var/lib/motioneye
msg_ok "Installed MotionEye"

msg_info "Creating Service"
curl -fsSL "https://raw.githubusercontent.com/motioneye-project/motioneye/dev/motioneye/extra/motioneye.systemd" -o "/etc/systemd/system/motioneye.service"
sed -i 's|^ExecStart=.*|ExecStart=/opt/motioneye/.venv/bin/meyectl startserver -c /etc/motioneye/motioneye.conf|' /etc/systemd/system/motioneye.service
systemctl daemon-reexec
systemctl enable -q --now motioneye
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
