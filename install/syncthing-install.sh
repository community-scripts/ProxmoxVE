#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://syncthing.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "syncthing" \
  "https://syncthing.net/release-key.gpg" \
  "https://apt.syncthing.net/" \
  "syncthing" \
  "stable-v2"

msg_info "Setting up Syncthing"
$STD apt install -y syncthing
systemctl enable -q --now syncthing@root
sleep 5
sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" /root/.local/state/syncthing/config.xml
systemctl restart syncthing@root
msg_ok "Setup Syncthing"

motd_ssh
customize
cleanup_lxc
