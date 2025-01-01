#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.inspircd.org/

# App Default Values
APP="InspIRCd"
var_tags="IRC"
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

  if [[ ! -f /lib/systemd/system/inspircd.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/inspircd/inspircd/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop inspircd
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/inspircd/inspircd/releases/download/v${RELEASE}/inspircd_${RELEASE}.deb12u1_amd64.deb
    apt-get install "./inspircd_${RELEASE}.deb12u1_amd64.deb" -y &>/dev/nul
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start inspircd
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/inspircd_${RELEASE}.deb12u1_amd64.deb
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
echo -e "${INFO}${YW} Server-Acces it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:6667${CL}"