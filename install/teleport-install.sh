#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://goteleport.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "teleport" \
  "https://deb.releases.teleport.dev/teleport-pubkey.asc" \
  "https://apt.releases.teleport.dev/debian" \
  "trixie" \
  "stable/v18"

msg_info "Configuring Teleport"
$STD apt install -y teleport
$STD teleport configure -o /etc/teleport.yaml
systemctl enable -q --now teleport
sleep 10
tctl users add teleport-admin --roles=editor,access --logins=root >~/teleportadmin.txt
sed -i "s|https://[^:]*:3080|https://${LOCAL_IP}:3080|g" ~/teleportadmin.txt
msg_ok "Configured Teleport"

motd_ssh
customize
cleanup_lxc
