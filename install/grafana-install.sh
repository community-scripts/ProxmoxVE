#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grafana.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y apt-transport-https
  msg_ok "Installed Dependencies"

  msg_info "Setting up Grafana Repository"
  setup_deb822_repo \
    "grafana" \
    "https://apt.grafana.com/gpg.key" \
    "https://apt.grafana.com" \
    "stable" \
    "main"
  msg_ok "Grafana Repository setup sucessfully"

  msg_info "Installing Grafana"
  $STD apt install -y grafana
  systemctl enable -q --now grafana-server
  msg_ok "Installed Grafana"
}

setup_alpine() {
  msg_info "Installing Grafana"
  $STD apk add grafana
  $STD sed -i '/http_addr/s/127.0.0.1/0.0.0.0/g' /etc/conf.d/grafana
  $STD rc-service grafana start
  $STD rc-update add grafana default
  msg_ok "Installed Grafana"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
