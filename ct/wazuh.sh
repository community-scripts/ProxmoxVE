#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wazuh.com/

APP="Wazuh"
var_tags="security;monitoring"
var_cpu="8"
var_ram="4096"
var_disk="24"
var_os="ubuntu"
var_version="22.04"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
   header_info
   check_container_storage
   check_container_resources
   if [[ ! -d /var ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
   fi
   msg_info "Updating ${APP} LXC"
   $STD apt-get update
   $STD apt-get -y upgrade
   msg_ok "Updated ${APP} LXC"
   exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:443${CL}"
