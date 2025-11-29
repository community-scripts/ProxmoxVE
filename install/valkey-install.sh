#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: pshankinclarke (lazarillo)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://valkey.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Valkey"
$STD apt update
$STD apt install -y valkey
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/valkey/valkey.conf
systemctl enable -q --now valkey-server
systemctl restart valkey-server
msg_ok "Installed Valkey"

motd_ssh
customize
cleanup_lxc
