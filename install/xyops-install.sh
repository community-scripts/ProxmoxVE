#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pixlcore/xyops

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3 \
  python3-setuptools \
  pkg-config \
  libssl-dev \
  zlib1g-dev
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "xyops" "pixlcore/xyops" "tarball"

msg_info "Building Application"
cd /opt/xyops
$STD npm install
$STD node bin/build.js dist
chmod 644 /opt/xyops/node_modules/useragent-ng/lib/regexps.js
msg_ok "Built Application"

fetch_and_deploy_gh_release "xysat" "pixlcore/xysat" "tarball" "latest" "/opt/xyops/satellite"

msg_info "Building xySat Satellite"
cd /opt/xyops/satellite
$STD npm install
msg_ok "Built xySat Satellite"

msg_info "Setting up Directories"
mkdir -p /opt/xyops/data /opt/xyops/logs /opt/xyops/temp /opt/xyops/conf
msg_ok "Set up Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/xyops.service
[Unit]
Description=xyOps Task Scheduler and Server Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/xyops
Environment=XYOPS_foreground=1
ExecStart=/usr/bin/node /opt/xyops/lib/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now xyops
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
