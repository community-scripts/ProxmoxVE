#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://transmissionbt.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Transmission"
  $STD apt install -y transmission-daemon
  systemctl stop transmission-daemon
  sed -i '{s/"rpc-whitelist-enabled": true/"rpc-whitelist-enabled": false/g; s/"rpc-host-whitelist-enabled": true,/"rpc-host-whitelist-enabled": false,/g}' /etc/transmission-daemon/settings.json
  systemctl start transmission-daemon
  msg_ok "Installed Transmission"
}

setup_alpine() {
  msg_info "Installing Transmission"
  $STD apk add --no-cache transmission-cli transmission-daemon
  $STD rc-service transmission-daemon start
  sleep 5
  $STD rc-service transmission-daemon stop
  sed -i '{s/"rpc-whitelist-enabled": true/"rpc-whitelist-enabled": false/g; s/"rpc-host-whitelist-enabled": true,/"rpc-host-whitelist-enabled": false,/g}' /var/lib/transmission/config/settings.json
  msg_ok "Installed Transmission"

  msg_info "Enabling Transmission Service"
  $STD rc-update add transmission-daemon default
  msg_ok "Enabled Transmission Service"

  msg_info "Starting Transmission"
  $STD rc-service transmission-daemon start
  msg_ok "Started Transmission"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
