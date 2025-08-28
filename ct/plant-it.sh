#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plant-it.org/

APP="Plant-it"
var_tags="${var_tags:-plants;garden}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/plant-it ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "plant-it" "MDeLuise/plant-it"; then
    msg_info "Stopping $APP"
    systemctl stop plant-it
    msg_ok "Stopped $APP"

    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "plant-it" "MDeLuise/plant-it" "singlefile" "latest" "/opt/plant-it/backend" "server.jar"
    fetch_and_deploy_gh_release "plant-it-front" "MDeLuise/plant-it" "prebuild" "latest" "/opt/plant-it/frontend" "client.tar.gz"

    msg_info "Starting $APP"
    systemctl start plant-it
    msg_ok "Started $APP"
    msg_ok "Update Successful"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
