#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stumpapp/stump

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "stump" "stumpapp/stump" "prebuild" "latest" "/opt/stump" "linux-build-results.zip"
chmod +x /opt/stump/stump_server
fetch_and_deploy_gh_release "pdfium" "bblanchon/pdfium-binaries" "prebuild" "latest" "/opt/pdfium" "pdfium-linux-x64.tgz"

msg_info "Creating Stump Service"
mkdir -p /opt/stump_data/{config,library}
cat <<EOF >/etc/systemd/system/stump.service
[Unit]
Description=Stump
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/stump
Environment=STUMP_CONFIG_DIR=/opt/stump_data/config
Environment=STUMP_CLIENT_DIR=/opt/stump/client
Environment=PDFIUM_PATH=/opt/pdfium/lib/libpdfium.so
ExecStart=/opt/stump/stump_server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stump
msg_ok "Created Stump Service"

motd_ssh
customize
cleanup_lxc
