#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.commafeed.com/#/welcome

# App Default Values
APP="CommaFeed"
var_tags="rss-reader"
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
  if [[ ! -d /opt/commafeed ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -sL https://api.github.com/repos/Athou/commafeed/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop commafeed
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to ${RELEASE}"
    wget -q https://github.com/Athou/commafeed/releases/download/${RELEASE}/commafeed-${RELEASE}-h2-jvm.zip
    unzip -q commafeed-${RELEASE}-h2-jvm.zip
    rsync -a --exclude 'data/' commafeed-${RELEASE}-h2/ /opt/commafeed/
    rm -rf commafeed-${RELEASE}-h2 commafeed-${RELEASE}-h2-jvm.zip
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start commafeed
    msg_ok "Started ${APP}"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
