#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ombi.io/

# App Default Values
APP="Ombi"
var_tags="media"
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
  if [[ ! -d /opt/ombi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -sL https://api.github.com/repos/Ombi-app/Ombi/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop ombi
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to ${RELEASE}"
    wget -q https://github.com/Ombi-app/Ombi/releases/download/${RELEASE}/linux-x64.tar.gz
    tar -xzf linux-x64.tar.gz -C /opt/ombi
    rm -rf linux-x64.tar.gz
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start ombi
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} ia already at ${RELEASE}."
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