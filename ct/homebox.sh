#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homebox.software/en/

# App Default Values
APP="HomeBox"
var_tags="inventory;household"
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
  if [[ ! -f /opt/homebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop homebox
    msg_ok "${APP} Stopped"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    rm -rf homebox_bak
    rm -rf /tmp/homebox.tar.gz
    mv homebox homebox_bak
    wget -qO /tmp/homebox.tar.gz https://github.com/sysadminsmedia/homebox/releases/download/${RELEASE}/homebox_Linux_x86_64.tar.gz
    tar -xzf /tmp/homebox.tar.gz -C /opt
    chmod +x /opt/homebox
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Homebox"

    msg_info "Starting ${APP}"
    systemctl start homebox
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7745${CL}"