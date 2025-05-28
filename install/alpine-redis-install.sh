#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redis.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Redis"
$STD apk add redis
$STD sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis.conf
$STD rc-update add redis default
$STD rc-service redis start
msg_ok "Installed Redis"

motd_ssh
customize
