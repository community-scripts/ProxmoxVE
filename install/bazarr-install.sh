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

msg_info "Setup Python3"
$STD apt-get install -y \
  python3 \
  python3-dev
msg_ok "Setup Python3"

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "bazarr" "morpheus65535/bazarr" "prebuild" "latest" "/opt/bazarr" "bazarr.zip"

msg_info "Installing Bazarr"
mkdir -p /var/lib/bazarr/
chmod 775 /opt/bazarr /var/lib/bazarr/
sed -i.bak 's/--only-binary=Pillow//g' /opt/bazarr/requirements.txt
$STD uv pip install -r /opt/bazarr/requirements.txt --system
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
ExecStart=/usr/bin/python3 /opt/bazarr/bazarr.py
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
