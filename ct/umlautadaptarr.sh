#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: elvito
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PCJones/UmlautAdaptarr

APP="UmlautAdaptarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/UmlautAdaptarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "UmlautAdaptarr" "PCJones/Umlautadaptarr"; then
    msg_info "Stopping Service"
    systemctl stop umlautadaptarr
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "UmlautAdaptarr" "PCJones/Umlautadaptarr" "prebuild" "latest" "/opt/UmlautAdaptarr" "linux-x64.zip"

    msg_info "Starting Service"
    systemctl start umlautadaptarr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5005${CL}"
