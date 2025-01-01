#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zoraxy.aroz.org/

# App Default Values
APP="Zoraxy"
var_tags="network"
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
  if [[ ! -d /opt/zoraxy/ ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/tobychui/zoraxy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating $APP to ${RELEASE}"
    systemctl stop zoraxy
    wget -q "https://github.com/tobychui/zoraxy/releases/download/${RELEASE}/zoraxy_linux_amd64"
    rm -rf /opt/zoraxy/zoraxy
    mv zoraxy_linux_amd64 /opt/zoraxy/zoraxy
    chmod +x /opt/zoraxy/zoraxy
    systemctl start zoraxy
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"