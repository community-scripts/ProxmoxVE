#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
curl -fsSL "https://linux-packages.resilio.com/resilio-sync/key.asc" >/etc/apt/trusted.gpg.d/resilio-sync.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/resilio-sync.asc] http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" >/etc/apt/sources.list.d/resilio-sync.list
$STD apt-get update
msg_ok "Resilio Sync Repository Setup"

msg_info "Installing Resilio Sync"
$STD apt-get install -y resilio-sync
sed -i "s/127.0.0.1:8888/0.0.0.0:8888/g" /etc/resilio-sync/config.json
systemctl enable -q resilio-sync
systemctl restart resilio-sync
msg_ok "Installed Resilio Sync"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
