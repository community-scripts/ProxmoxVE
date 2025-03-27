#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ersatztv.org/

APP="ErsatzTV"
var_tags="iptv"
var_cpu="1"
var_ram="1024"
var_disk="5"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/ErsatzTV ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/ErsatzTV/ErsatzTV/releases | grep -oP '"tag_name": "\K[^"]+' | head -n 1)
  if [[ ! -f /opt/${APP}_version.txt && $(echo "x.x.x" >/opt/${APP}_version.txt) || "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ErsatzTV"
    systemctl stop ersatzTV
    msg_ok "Stopped ErsatzTV"

    msg_info "Updating ErsatzTV"
    cp -R /opt/ErsatzTV/ ErsatzTV-backup
    rm ErsatzTV-backup/ErsatzTV
    rm -rf /opt/ErsatzTV
    temp_file=$(mktemp)
    wget -qO- https://github.com/ErsatzTV/ErsatzTV/releases/download/${RELEASE}/ErsatzTV-${RELEASE}-linux-x64.tar.gz -O "$temp_file"
    tar -xzf "$temp_file"
    mv /opt/ErsatzTV-${RELEASE}-linux-x64 /opt/ErsatzTV
    cp -R ErsatzTV-backup/* /opt/ErsatzTV/
    rm -rf ErsatzTV-backup
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ErsatzTV"

    msg_info "Starting ErsatzTV"
    systemctl start ersatzTV
    msg_ok "Started ErsatzTV"

    msg_info "Cleaning Up"
    rm -f ${temp_file}
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8409${CL}"
