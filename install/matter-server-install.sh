#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matter-js/python-matter-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libuv1 \
  libjson-c5 \
  libnl-3-200 \
  libnl-route-3-200 \
  iputils-ping \
  iproute2
msg_ok "Installed Dependencies"

UV_PYTHON="3.12" setup_uv

msg_info "Setting up Matter Server"
mkdir -p /opt/matter-server/data/credentials
if [ -L /data ]; then
  rm -f /data
fi
if [ ! -e /data ]; then
  ln -s /opt/matter-server/data /data
fi
$STD uv venv /opt/matter-server/.venv
MATTER_VERSION=$(get_latest_github_release "matter-js/python-matter-server")
$STD uv pip install --python /opt/matter-server/.venv/bin/python "python-matter-server[server]==${MATTER_VERSION}"
echo "${MATTER_VERSION}" >~/.matter-server
msg_ok "Set up Matter Server"

fetch_and_deploy_gh_release "chip-ota-provider-app" "home-assistant-libs/matter-linux-ota-provider" "singlefile" "latest" "/usr/local/bin" "chip-ota-provider-app-x86-64"

msg_info "Configuring Network"
cat <<EOF >/etc/sysctl.d/99-matter.conf
net.ipv4.igmp_max_memberships=1024
EOF
$STD sysctl -p /etc/sysctl.d/99-matter.conf
msg_ok "Configured Network"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/matter-server.service
[Unit]
Description=Matter Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/matter-server/.venv/bin/matter-server --storage-path /data --paa-root-cert-dir /data/credentials
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now matter-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
