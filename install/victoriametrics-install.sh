#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sudo \
  curl \
  mc
msg_ok "Installed Dependencies"

msg_info "Setup VictoriaMetrics"
temp_dir=$(mktemp -d)
cd $temp_dir
mkdir -p /opt/victoriametrics/data
RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/victoria-metrics-linux-amd64-v${RELEASE}.tar.gz
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/vmutils-linux-amd64-v${RELEASE}.tar.gz
tar -xf victoria-metrics-linux-amd64-v${RELEASE}.tar.gz -C /opt/victoriametrics
tar -xf vmutils-linux-amd64-v${RELEASE}.tar.gz -C /opt/victoriametrics
chmod +x /opt/victoriametrics/*
msg_ok "Setup VictoriaMetrics"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/victoriametrics.service
[Unit]
Description=VictoriaMetrics Service

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/victoriametrics
ExecStart=/opt/victoriametrics/victoria-metrics-prod --storageDataPath="/opt/victoriametrics/data"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now victoriametrics
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $temp_dir
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
