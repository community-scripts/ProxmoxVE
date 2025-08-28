#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: TheRealVira
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pf2etools.com/

APP="Pf2eTools"
var_tags="${var_tags:-wiki}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d "/opt/${APP}" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "pf2etools" "Pf2eToolsOrg/Pf2eTools"; then
    msg_info "Updating System"
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated System"

    rm -rf /opt/Pf2eTools
    fetch_and_deploy_gh_release "pf2etools" "Pf2eToolsOrg/Pf2eTools" "tarball" "latest" "/opt/Pf2eTools"

    msg_info "Updating ${APP}"
    cd /opt/Pf2eTools
    $STD npm install
    $STD npm run build
    chown -R www-data: "/opt/${APP}"
    chmod -R 755 "/opt/${APP}"
    msg_ok "Updated ${APP}"
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
