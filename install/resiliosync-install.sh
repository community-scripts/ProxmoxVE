#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: David Bennett (dbinit)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.resilio.com/sync

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up Resilio Sync Repository"
setup_deb822_repo \
  "resilio" \
  "https://linux-packages.resilio.com/resilio-sync/key.asc" \
  "http://linux-packages.resilio.com/resilio-sync/deb" \
  "resilio-sync" \
  "non-free"
msg_ok "Setup Resilio Sync Repository"

msg_info "Installing Resilio Sync"
$STD apt install -y resilio-sync
sed -i "s/127.0.0.1:8888/0.0.0.0:8888/g" /etc/resilio-sync/config.json
systemctl enable -q resilio-sync
systemctl restart resilio-sync
msg_ok "Installed Resilio Sync"

motd_ssh
customize
cleanup_lxc
