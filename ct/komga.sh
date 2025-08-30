#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: madelyn (DysfunctionalProgramming)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komga.org/

APP="Komga"
var_tags="${var_tags:-media;eBook;comic}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [[ ! -f /opt/komga/komga.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "komga" "gotson/komga"; then
    msg_info "Stopping ${APP}"
    systemctl stop komga
    msg_ok "Stopped ${APP}"

    rm -f /opt/komga/komga.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "komga-org" "gotson/komga" "singlefile" "latest" "/opt/komga" "komga*.jar"
    mv /opt/komga/komga-*.jar /opt/komga/komga.jar

    msg_info "Starting ${APP}"
    systemctl start komga
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:25600${CL}"
