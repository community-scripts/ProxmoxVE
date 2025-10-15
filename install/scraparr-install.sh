#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: JasonGreenC
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thecfu/scraparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "scrappar" "thecfu/scraparr" "tarball" "latest" "/opt/scraparr"

msg_info "Installing Scraparr"
cd /opt/scraparr
$STD uv venv /opt/scraparr/.venv
$STD /opt/scraparr/.venv/bin/python -m ensurepip --upgrade
$STD /opt/scraparr/.venv/bin/python -m pip install --upgrade pip
$STD /opt/scraparr/.venv/bin/python -m pip install -r /opt/scraparr/src/scraparr/requirements.txt
chmod -R 755 /opt/scraparr
mkdir -p /scraparr/config
mv /opt/scraparr/config.yaml /scraparr/config/config.yaml
chmod -R 755 /scraparr
msg_ok "Installed Scraparr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/scraparr.service
[Unit]
Description=Scraparr
Wants=network-online.target
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/scraparr/src
ExecStart=/opt/scraparr/.venv/bin/python -m scraparr.scraparr
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now scraparr
msg_ok "Configured Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
