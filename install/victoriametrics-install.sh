#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Getting latest version of VictoriaMetrics"
victoriametrics_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
  jq -r '.assets[].name' |
  grep -E '^victoria-metrics-linux-amd64-v[0-9.]+\.tar\.gz$')
vmutils_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
  jq -r '.assets[].name' |
  grep -E '^vmutils-linux-amd64-v[0-9.]+\.tar\.gz$')
msg_ok "Got latest version of VictoriaMetrics"

fetch_and_deploy_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$victoriametrics_filename"
fetch_and_deploy_gh_release "vmutils" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$vmutils_filename"

read -r -p "${TAB3}Would you like to add VictoriaLogs? <y/N> " prompt

if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "victoria-logs-linux-amd64*.tar.gz"
  fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "vlutils-linux-amd64*.tar.gz"
fi

msg_info "Setup VictoriaMetrics"
mkdir -p /opt/victoriametrics/data
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

if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  cat <<EOF >/etc/systemd/system/victoriametrics-logs.service
[Unit]
Description=VictoriaMetrics Service

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/victoriametrics
ExecStart=/opt/victoriametrics/victoria-logs-prod

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now victoriametrics-logs
fi
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
