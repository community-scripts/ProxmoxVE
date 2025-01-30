#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zwave-js.github.io/zwave-js-ui/#/

# App Default Values
APP="Zwave-JS-UI"
var_tags="smarthome;zwave"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="0"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
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
  RELEASE=$(curl -s https://api.github.com/repos/zwave-js/zwave-js-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop zwave-js-ui
    msg_ok "Stopped Service"

    msg_info "Updating Z-Wave JS UI"
    rm -rf /opt/zwave-js-ui/*
    cd /opt/zwave-js-ui
    wget -q https://github.com/zwave-js/zwave-js-ui/releases/download/${RELEASE}/zwave-js-ui-${RELEASE}-linux.zip
    unzip -q zwave-js-ui-${RELEASE}-linux.zip
    msg_ok "Updated Z-Wave JS UI"

    msg_info "Starting Service"
    systemctl start zwave-js-ui
    msg_ok "Started Service"

    msg_info "Cleanup"
    rm -rf /opt/zwave-js-ui/zwave-js-ui-${RELEASE}-linux.zip
    rm -rf /opt/zwave-js-ui/store
    msg_ok "Cleaned"
    msg_ok "Updated Successfully!\n"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
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