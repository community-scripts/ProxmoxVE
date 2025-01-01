#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://myspeed.dev/

# App Default Values
APP="MySpeed"
var_tags="tracking"
var_cpu="1"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

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
  if [[ ! -d /opt/myspeed ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(wget -q https://github.com/gnmyt/myspeed/releases/latest -O - | grep "title>Release" | cut -d " " -f 5)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Stopping ${APP} Service"
    systemctl stop myspeed
    msg_ok "Stopped ${APP} Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    rm -rf myspeed_bak
    mv myspeed myspeed_bak
    wget -q https://github.com/gnmyt/myspeed/releases/download/v$RELEASE/MySpeed-$RELEASE.zip
    unzip -q MySpeed-$RELEASE.zip -d myspeed
    cd myspeed
    npm install >/dev/null 2>&1
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP} Service"
    systemctl start myspeed
    msg_ok "Started ${APP} Service"

    msg_info "Cleaning up"
    rm -rf MySpeed-$RELEASE.zip
    msg_ok "Cleaned"

    msg_ok "Updated Successfully!\n"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5216${CL}"