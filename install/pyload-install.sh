#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pyload/pyload

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  unrar-free \
  p7zip-full \
  tesseract-ocr
msg_ok "Installed Dependencies"

UV_PYTHON="3.13" setup_uv

msg_info "Setting up pyLoad"
mkdir -p /opt/pyload_data/{userdir,downloads}
$STD uv venv --python 3.13 /opt/pyload/.venv
$STD uv pip install --python /opt/pyload/.venv --prerelease allow "pyload-ng[all]"
msg_ok "Set up pyLoad"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pyload.service
[Unit]
Description=pyLoad Download Manager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pyload
ExecStart=/opt/pyload/.venv/bin/pyload --userdir /opt/pyload_data/userdir --storagedir /opt/pyload_data/downloads
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pyload
msg_ok "Created Service"

msg_info "Configuring Web Interface"
for _ in {1..30}; do
  [[ -f /opt/pyload_data/userdir/settings/pyload.cfg ]] && break
  sleep 1
done
sed -i 's|^\([[:space:]]*ip host : "IP address"\) = localhost$|\1 = 0.0.0.0|' /opt/pyload_data/userdir/settings/pyload.cfg

# pyLoad rewrites storage_folder from --storagedir on every start; the first start seeded it.
sed -i 's| --storagedir /opt/pyload_data/downloads||' /etc/systemd/system/pyload.service
systemctl daemon-reload
systemctl restart pyload
msg_ok "Configured Web Interface"

motd_ssh
customize
cleanup_lxc
