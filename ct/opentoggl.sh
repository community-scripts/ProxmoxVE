#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CorrectRoadH
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CorrectRoadH/opentoggl

APP="OpenToggl"
var_tags="${var_tags:-time-tracking}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -f /usr/local/bin/opentoggl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "opentoggl" "CorrectRoadH/opentoggl"; then
    msg_info "Stopping Service"
    systemctl stop opentoggl
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "opentoggl" "CorrectRoadH/opentoggl" "singlefile" "latest" "/usr/local/bin" "opentoggl-linux-amd64"
    chmod +x /usr/local/bin/opentoggl

    msg_info "Starting Service"
    systemctl start opentoggl
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
