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

setup_deb_based() {
  msg_info "Setting up ntfy"
  setup_deb822_repo \
    "ntfy" \
    "https://archive.ntfy.sh/apt/keyring.gpg" \
    "https://archive.ntfy.sh/apt/" \
    "stable"
  $STD apt install -y ntfy
  systemctl enable -q --now ntfy
  msg_ok "Setup ntfy"
}

setup_alpine() {
  msg_info "Installing ntfy"
  $STD apk add --no-cache ntfy ntfy-openrc libcap
  sed -i '/^listen-http/s/^\(.*\)$/#\1\n/' /etc/ntfy/server.yml
  setcap 'cap_net_bind_service=+ep' /usr/bin/ntfy
  $STD rc-update add ntfy default
  $STD service ntfy start
  msg_ok "Installed ntfy"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
