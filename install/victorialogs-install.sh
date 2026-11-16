#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nicolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://victoriametrics.com/products/victorialogs/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victorialogs" "victoria-logs-linux-$(arch_resolve amd64 arm64)-v*[0-9].tar.gz"
fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/vlutils" "vlutils-linux-$(arch_resolve amd64 arm64)-v*[0-9].tar.gz"

msg_info "Creating Service"
mkdir -p /opt/victorialogs_data
cat <<EOF >/etc/systemd/system/victorialogs.service
[Unit]
Description=VictoriaLogs Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/victorialogs
ExecStart=/opt/victorialogs/victoria-logs-prod -storageDataPath=/opt/victorialogs_data -httpListenAddr=:9428 -syslog.listenAddr.tcp=:514 -syslog.listenAddr.udp=:514
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now victorialogs
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
