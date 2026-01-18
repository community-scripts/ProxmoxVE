#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ntfy.sh/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up ntfy"
setup_deb822_repo \
  "ntfy" \
  "https://archive.ntfy.sh/apt/keyring.gpg" \
  "https://archive.ntfy.sh/apt/" \
  "stable"
$STD apt install -y ntfy
systemctl enable -q --now ntfy
msg_ok "Setup ntfy"

motd_ssh
customize
cleanup_lxc
