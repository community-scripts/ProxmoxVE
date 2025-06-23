#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Johann3s-H (An!ma)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Forgejo"
$STD apk add --no-cache forgejo
msg_ok "Installed Forgejo"

msg_info "Enabling Forgejo Service"
$STD rc-update add forgejo default
msg_ok "Enabled Forgejo Service"

msg_info "Starting Forgejo"
$STD service forgejo start
msg_ok "Started Forgejo"

motd_ssh
customize