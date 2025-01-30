#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FlareSolverr/FlareSolverr

# App Default Values
APP="FlareSolverr"
var_tags="proxy"
var_cpu="2"
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
  if [[ ! -f /etc/systemd/system/flaresolverr.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(wget -q https://github.com/FlareSolverr/FlareSolverr/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating $APP LXC"
    systemctl stop flaresolverr
    wget -q https://github.com/FlareSolverr/FlareSolverr/releases/download/$RELEASE/flaresolverr_linux_x64.tar.gz
    tar -xzf flaresolverr_linux_x64.tar.gz -C /opt
    rm flaresolverr_linux_x64.tar.gz
    systemctl start flaresolverr
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP LXC"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"