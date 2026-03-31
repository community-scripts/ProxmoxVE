#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: sdblepas
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sdblepas/CinePlete

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  curl \
  ca-certificates
msg_ok "Installed Dependencies"

msg_info "Installing ${APP}"
fetch_and_deploy_gh_release "cineplete" "sdblepas/CinePlete" "tarball" "latest" "/opt/cineplete"
mkdir -p /data /config
python3 -m venv /opt/cineplete/.venv
/opt/cineplete/.venv/bin/pip install --quiet --upgrade pip
/opt/cineplete/.venv/bin/pip install --quiet -r /opt/cineplete/requirements.txt
msg_ok "Installed ${APP}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cineplete.service
[Unit]
Description=CinePlete — Movie library gap finder
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cineplete
Environment=DATA_DIR=/data
Environment=CONFIG_DIR=/config
Environment=STATIC_DIR=/opt/cineplete/static
ExecStart=/opt/cineplete/.venv/bin/uvicorn app.web:app --host 0.0.0.0 --port 7474 --workers 1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cineplete
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
