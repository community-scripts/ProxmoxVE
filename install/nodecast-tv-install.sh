#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/technomancer702/nodecast-tv

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "nodecast-tv" "technomancer702/nodecast-tv"
setup_nodejs

msg_info "Installing Dependencies"
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing Modules"
cd /opt/nodecast-tv
$STD npm install
msg_ok "Installed Modules"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nodecast-tv.service
[Unit]
Description=nodecast-tv
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/opt/nodecast-tv
ExecStart=/bin/npm run dev
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nodecast-tv
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
