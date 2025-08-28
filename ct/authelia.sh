#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.authelia.com/

APP="Authelia"
TAGS=""
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
base_settings

variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d "/etc/authelia/" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "authelia" "authelia/authelia"; then
    $STD apt-get update
    $STD apt-get -y upgrade

    fetch_and_deploy_gh_release "authelia" "authelia/authelia" "binary"

    msg_info "Cleaning Up"
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleanup Completed"
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
echo -e "${TAB}${GATEWAY}${BGN}https://YOUR_AUTHELIA_URL${CL}"
