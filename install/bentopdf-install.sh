#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

msg_info "Setup BentoPDF"
cd /opt/bentopdf
$STD npm ci --no-audit --no-fund
export SIMPLE_MODE=true
$STD npm run build -- --mode production
msg_ok "Setup BentoPDF"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bentopdf.service
[Unit]
Description=BentoPDF Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bentopdf
ExecStart=/usr/bin/npx serve dist -p 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now bentopdf
msg_ok "Created & started service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
