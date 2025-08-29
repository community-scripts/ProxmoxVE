#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zwave-js.github.io/zwave-js-ui/#/

APP="Zwave-JS-UI"
var_tags="${var_tags:-smarthome;zwave}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zwave-js-ui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "zwave-js-ui" "zwave-js/zwave-js-ui"; then
    msg_info "Stopping Service"
    systemctl stop zwave-js-ui
    msg_ok "Stopped Service"

    rm -rf /opt/zwave-js-ui/*
    fetch_and_deploy_gh_release "zwave-js-ui" "zwave-js/zwave-js-ui" "prebuild" "latest" "/opt/zwave-js-ui" "zwave-js-ui*-linux.zip"

    msg_info "Starting Service"
    systemctl start zwave-js-ui
    msg_ok "Started Service"

    msg_info "Cleanup"
    rm -rf /opt/zwave-js-ui/store
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8091${CL}"
