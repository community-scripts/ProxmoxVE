#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Marfnl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus/blackbox_exporter

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "blackbox-exporter" "prometheus/blackbox_exporter" "prebuild" "latest" "/opt/blackbox-exporter" "blackbox_exporter-*.linux-amd64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/blackbox-exporter.service
[Unit]
Description=Blackbox Exporter Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/blackbox-exporter
ExecStart=/opt/blackbox-exporter/blackbox_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now blackbox-exporter
msg_ok "Service Created"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
