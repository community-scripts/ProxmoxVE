#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dedicatedcode/reitti

APP="Reitti"
var_tags="${var_tags:-location-tracker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/reitti/reitti.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "reitti" "dedicatedcode/reitti"; then
    msg_info "Stopping Service"
    systemctl stop reitti
    msg_ok "Stopped Service"

    rm -f /opt/reitti/reitti.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "reitti" "dedicatedcode/reitti" "singlefile" "latest" "/opt/reitti" "reitti-app.jar"
    mv /opt/reitti/reitti-*.jar /opt/reitti/reitti.jar

    msg_info "Starting Service"
    systemctl start reitti
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  if check_for_gh_release "photon" "komoot/photon"; then
    msg_info "Stopping Service"
    systemctl stop photon
    msg_ok "Stopped Service"

    rm -f /opt/photon/photon.jar
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "photon" "komoot/photon" "singlefile" "latest" "/opt/photon" "photon-0*.jar"
    mv /opt/photon/photon-*.jar /opt/photon/photon.jar

    msg_info "Starting Service"
    systemctl start photon
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
