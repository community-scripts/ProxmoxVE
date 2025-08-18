#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: twingate-andrewb
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.twingate.com/docs/

APP="Twingate-Connector"
var_tags="${var_tags:-network;connector;twingate}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-3}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /lib/systemd/system/twingate-connector.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP}"
  $STD apt update
  $STD apt install -yq twingate-connector
  $STD systemctl restart twingate-connector
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "All Finished! If you need to update your access or refresh tokens, they can be found in /etc/twingate/connector.conf"
