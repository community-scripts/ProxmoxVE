#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bazarr.media/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Bazarr"
mkdir -p /var/lib/bazarr/
curl -fsSL "https://github.com/morpheus65535/bazarr/releases/latest/download/bazarr.zip" -o "bazarr.zip"
$STD unzip bazarr -d /opt/bazarr
chmod 775 /opt/bazarr /var/lib/bazarr/
cd /opt/bazarr
$STD uv venv /opt/bazarr/.venv
$STD /opt/bazarr/.venv/bin/python -m ensurepip --upgrade
$STD /opt/bazarr/.venv/bin/python -m pip install --upgrade pip
$STD /opt/bazarr/.venv/bin/python -m pip install -r requirements.txt
msg_ok "Installed Bazarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bazarr.service
[Unit]
Description=Bazarr Daemon
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/bazarr/
UMask=0002
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=/opt/bazarr/.venv/bin/python /opt/bazarr/bazarr.py
KillSignal=SIGINT
TimeoutStopSec=20
SyslogIdentifier=bazarr

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bazarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf bazarr.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
