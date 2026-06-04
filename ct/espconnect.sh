#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: John Lombardo (programbo) 
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thelastoutpostworkshop/ESPConnect

APP="ESPConnect"
var_tags="${var_tags:-iot;esp32;flash}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/espconnect ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "espconnect" "thelastoutpostworkshop/ESPConnect"; then
    msg_info "Stopping Nginx"
    systemctl stop nginx
    msg_ok "Stopped Nginx"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "espconnect" "thelastoutpostworkshop/ESPConnect" "prebuild" "latest" "/opt/espconnect" "dist.zip"

    msg_info "Starting Nginx"
    systemctl start nginx
    msg_ok "Started Nginx"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"
