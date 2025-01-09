#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: thisisjeron
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://calibre-ebook.com

# App Default Values
APP="Calibre-Server"
var_tags="eBook"
var_cpu="2"
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

  if [[ ! -f /etc/systemd/system/calibre-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop calibre-server
  msg_ok "Stopped ${APP}"
  
  msg_info "Updating ${APP} Packages"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  msg_ok "Packages updated"

  msg_info "Updating Calibre (latest)"
  bash -c "$(curl -fsSL https://download.calibre-ebook.com/linux-installer.sh)"
  msg_ok "Updated Calibre"

  msg_info "Starting ${APP}"
  systemctl start calibre-server
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8180${CL}" 
