#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mathiasnagler
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/router-for-me/CLIProxyAPI

APP="CLIProxyAPI"
var_tags="${var_tags:-ai;proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d /opt/cliproxyapi ]]; then
    msg_error "No CLIProxyAPI Installation Found!"
    exit
  fi

  if check_for_gh_release "cliproxyapi" "router-for-me/CLIProxyAPI"; then
    msg_info "Stopping CLIProxyAPI"
    systemctl stop cliproxyapi
    msg_ok "Stopped CLIProxyAPI"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cliproxyapi" "router-for-me/CLIProxyAPI" "prebuild" "latest" "/opt/cliproxyapi" "CLIProxyAPI_*_linux_amd64.tar.gz"

    msg_info "Starting CLIProxyAPI"
    systemctl start cliproxyapi
    msg_ok "Started CLIProxyAPI"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8317${CL}"
