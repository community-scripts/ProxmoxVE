#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: zackwithak13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.uhfapp.com/server

APP="UHF"
var_tags="${var_tags:-media}"
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
  if [[ ! -d /opt/uhf-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "uhf-server" "swapplications/uhf-server-dist"; then
    msg_info "Stopping Service"
    systemctl stop uhf-server
    msg_ok "Stopped Service"

    msg_info "Updating LXC"
    $STD apt update
    $STD apt -y upgrade
    msg_ok "Updated LXC"

    fetch_and_deploy_gh_release "comskip" "swapplications/comskip" "prebuild" "latest" "/opt/comskip" "comskip-x64-*.zip"
    fetch_and_deploy_gh_release "uhf-server" "swapplications/uhf-server-dist" "prebuild" "latest" "/opt/uhf-server" "UHF.Server-linux-x64-*.zip"

    msg_info "Starting Service"
    systemctl start uhf-server
    msg_ok "Started Service"

    msg_info "Cleaning up"
    $STD apt -y autoremove
    $STD apt -y autoclean
    $STD apt -y clean
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7568${CL}"
