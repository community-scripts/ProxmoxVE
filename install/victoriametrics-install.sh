#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

vm_releases_json="$(mktemp)"
github_api_call "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases" "$vm_releases_json"
victoriametrics_release=$(jq -r --arg a "$(arch_resolve)" '.[] | select(.assets[].name | match("^victoria-metrics-linux-" + $a + "-v[0-9.]+.tar.gz$")) | .tag_name' "$vm_releases_json" |
  head -n 1)
rm -f "$vm_releases_json"
victoriametrics_filename="victoria-metrics-linux-$(arch_resolve)-${victoriametrics_release}.tar.gz"
vmutils_filename="vmutils-linux-$(arch_resolve)-${victoriametrics_release}.tar.gz"
msg_ok "Got version $victoriametrics_release of VictoriaMetrics"

fetch_and_deploy_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics" "prebuild" "$victoriametrics_release" "/opt/victoriametrics" "$victoriametrics_filename"
fetch_and_deploy_gh_release "vmutils" "VictoriaMetrics/VictoriaMetrics" "prebuild" "$victoriametrics_release" "/opt/victoriametrics" "$vmutils_filename"

read -r -p "${TAB3}Would you like to add VictoriaLogs? <y/N> " prompt

if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  vl_release_json="$(mktemp)"
  github_api_call "https://api.github.com/repos/VictoriaMetrics/VictoriaLogs/releases/latest" "$vl_release_json"
  vmlogs_filename=$(jq -r '.assets[].name' "$vl_release_json" |
    grep -E "^victoria-logs-linux-$(arch_resolve)-v[0-9.]+\.tar\.gz$")
  vlutils_filename=$(jq -r '.assets[].name' "$vl_release_json" |
    grep -E "^vlutils-linux-$(arch_resolve)-v[0-9.]+\.tar\.gz$")
  rm -f "$vl_release_json"
  fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "$vmlogs_filename"
  fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "$vlutils_filename"
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
cleanup_lxc
