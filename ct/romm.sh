#!/usr/bin/env bash

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2025 community-scripts ORG
# Author: DevelopmentCats
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://git.chesher.xyz/cat/romm-proxmox-ve-script

APP="RomM"
var_tags="media;utility"
var_cpu="4"
var_ram="2048"
var_disk="10"
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

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping ${APP} containers"
  cd /opt/romm && docker compose down
  msg_ok "Stopped ${APP} containers"
  
  msg_info "Updating ${APP} containers"
  cd /opt/romm && docker compose pull
  msg_ok "Updated ${APP} containers"
  
  msg_info "Starting ${APP} containers"
  cd /opt/romm && docker compose up -d
  msg_ok "Started ${APP} containers"
  
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
