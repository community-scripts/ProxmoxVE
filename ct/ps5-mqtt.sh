#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: liecno
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FunkeyFlo/ps5-mqtt/

APP="PS5-MQTT"
var_tags="${var_tags:-smarthome;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/ps5-mqtt ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi
  if check_for_gh_release "ps5-mqtt" "FunkeyFlo/ps5-mqtt"; then
    msg_info "Stopping service"
    systemctl stop ps5-mqtt
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "ps5-mqtt" "FunkeyFlo/ps5-mqtt" "tarball"

    msg_info "Configuring ${APP}"
    cd /opt/ps5-mqtt/ps5-mqtt/
    $STD npm install
    $STD npm run build
    msg_ok "Configured ${APP}"

    msg_info "Starting service"
    systemctl start ps5-mqtt
    msg_ok "Started service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8645${CL}"
