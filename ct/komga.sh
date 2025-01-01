#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: madelyn (DysfunctionalProgramming)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komga.org/

# App Default Values
APP="Komga"
var_tags="media;eBook;comic"
var_cpu="1"
var_ram="2048"
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
  if [[ ! -f /opt/komga/komga.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP}"
  RELEASE=$(curl -s https://api.github.com/repos/gotson/komga/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop komga
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to ${RELEASE}"
    wget -q "https://github.com/gotson/komga/releases/download/${RELEASE}/komga-${RELEASE}.jar"
    rm -rf /opt/komga/komga.jar
    mv -f komga-${RELEASE}.jar /opt/komga/komga.jar
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start komga
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:25600${CL}"
