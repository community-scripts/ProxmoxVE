#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dashy.to/

# App Default Values
APP="Dashy"
var_tags="dashboard"
var_cpu="2"
var_ram="2048"
var_disk="6"
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
  if [[ ! -d /opt/dashy/public/ ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -sL https://api.github.com/repos/Lissy93/dashy/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop dashy
    msg_ok "Stopped ${APP}"

    msg_info "Backing up conf.yml"
    cd ~
    if [[ -f /opt/dashy/public/conf.yml ]]; then
      cp -R /opt/dashy/public/conf.yml conf.yml
    else
      cp -R /opt/dashy/user-data/conf.yml conf.yml
    fi
    msg_ok "Backed up conf.yml"

    msg_info "Updating ${APP} to ${RELEASE}"
    rm -rf /opt/dashy
    mkdir -p /opt/dashy
    wget -qO- https://github.com/Lissy93/dashy/archive/refs/tags/${RELEASE}.tar.gz | tar -xz -C /opt/dashy --strip-components=1
    cd /opt/dashy
    npm install
    npm run build
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Restoring conf.yml"
    cd ~
    cp -R conf.yml /opt/dashy/user-data
    msg_ok "Restored conf.yml"

    msg_info "Cleaning"
    rm -rf conf.yml /opt/dashy/public/conf.yml
    msg_ok "Cleaned"

    msg_info "Starting Dashy"
    systemctl start dashy
    msg_ok "Started Dashy"
    msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4000${CL}"