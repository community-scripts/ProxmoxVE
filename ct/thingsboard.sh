#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thingsboard/thingsboard

APP="ThingsBoard"
var_tags="${var_tags:-iot;platform}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /usr/share/thingsboard ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "thingsboard" "thingsboard/thingsboard"; then
    msg_info "Stopping Service"
    systemctl stop thingsboard
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "thingsboard" "thingsboard/thingsboard" "binary" "latest" "/tmp" "thingsboard-*.deb"

    msg_info "Running Database Upgrade"
    $STD /usr/share/thingsboard/bin/install/upgrade.sh
    msg_ok "Ran Database Upgrade"

    msg_info "Starting Service"
    systemctl start thingsboard
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
