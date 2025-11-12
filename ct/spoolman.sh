#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Donkie/Spoolman

APP="Spoolman"
var_tags="${var_tags:-3d-printing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/spoolman ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://github.com/Donkie/Spoolman/releases/latest | grep "title>Release" | cut -d " " -f 4)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Stopping Service"
    systemctl stop spoolman
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    rm -rf spoolman_bak
    mv spoolman spoolman_bak
    curl -fsSL "https://github.com/Donkie/Spoolman/releases/download/${RELEASE}/spoolman.zip" -o $(basename "https://github.com/Donkie/Spoolman/releases/download/${RELEASE}/spoolman.zip")
    $STD unzip spoolman.zip -d spoolman
    cd spoolman
    $STD pip3 install -r requirements.txt
    curl -fsSL "https://raw.githubusercontent.com/Donkie/Spoolman/master/.env.example" -o ".env"
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting Service"
    systemctl start spoolman
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/spoolman.zip
    msg_ok "Cleaned"

    msg_ok "Updated successfully!"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7912${CL}"
