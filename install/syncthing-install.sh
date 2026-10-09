#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
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

setup_deb_based() {
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
}

setup_alpine() {
  msg_info "Setup Syncthing"
  $STD apk add --no-cache syncthing
  rc-service syncthing start
  sleep 3
  rc-service syncthing stop
  sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" /var/lib/syncthing/.local/state/syncthing/config.xml
  msg_ok "Setup Syncthing"

  msg_info "Enabling Syncthing Service"
  $STD rc-update add syncthing default
  msg_ok "Enabled Syncthing Service"

  msg_info "Starting Syncthing"
  $STD rc-service syncthing start
  msg_ok "Started Syncthing"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
