#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prometheus.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Prometheus"
$STD apk add --no-cache prometheus
msg_ok "Installed Prometheus"

msg_info "Enabling Prometheus Service"
$STD rc-update add prometheus default
msg_ok "Enabled Prometheus Service"

msg_info "Starting Prometheus"
$STD service prometheus start
msg_ok "Started Prometheus"

motd_ssh
customize
