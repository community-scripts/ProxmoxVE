#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lubelogger.com/

# App Default Values
APP="LubeLogger"
var_tags="verhicle;car"
var_cpu="1"
var_ram="512"
var_disk="2"
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
  if [[ ! -f /etc/systemd/system/lubelogger.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/hargata/lubelog/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  RELEASE_TRIMMED=$(echo "${RELEASE}" | tr -d ".")
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop lubelogger
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/hargata/lubelog/releases/download/v${RELEASE}/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
    mkdir -p /tmp/lubeloggerData/wwwroot
    cp /opt/lubelogger/appsettings.json /tmp/lubeloggerData/appsettings.json
    cp -r /opt/lubelogger/config /tmp/lubeloggerData/
    cp -r /opt/lubelogger/data /tmp/lubeloggerData/
    [[ -e /opt/lubelogger/wwwroot/translations ]] && cp -r /opt/lubelogger/wwwroot/translations /tmp/lubeloggerData/wwwroot/
    [[ -e /opt/lubelogger/wwwroot/documents ]] && cp -r /opt/lubelogger/wwwroot/documents /tmp/lubeloggerData/wwwroot/
    [[ -e /opt/lubelogger/wwwroot/images ]] && cp -r /opt/lubelogger/wwwroot/images /tmp/lubeloggerData/wwwroot/
    [[ -e /opt/lubelogger/wwwroot/temp ]] && cp -r /opt/lubelogger/wwwroot/temp /tmp/lubeloggerData/wwwroot/
    [[ -e /opt/lubelogger/log ]] && cp -r /opt/lubelogger/log /tmp/lubeloggerData/
    rm -rf /opt/lubelogger
    unzip -qq LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip -d lubelogger
    chmod 700 /opt/lubelogger/CarCareTracker
    cp -rf /tmp/lubeloggerData/* /opt/lubelogger/
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start lubelogger
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
    rm -rf /tmp/lubeloggerData
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
