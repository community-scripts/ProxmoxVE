#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Gitea"
$STD apk add --no-cache gitea
msg_ok "Installed Gitea"

msg_info "Enabling Gitea Service"
$STD rc-update add gitea default
msg_ok "Enabled Gitea Service"

msg_info "Starting Gitea"
$STD service gitea start
msg_ok "Started Gitea"

motd_ssh
customize
