#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cryptpad/cryptpad

APP="CryptPad"
var_tags="${var_tags:-docs;office}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d "/opt/cryptpad" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "cryptpad" "cryptpad/cryptpad"; then
    msg_info "Stopping Service"
    systemctl stop cryptpad
    msg_info "Stopped Service"

    msg_info "Backing up configuration"
    [ -f /opt/cryptpad/config/config.js ] && mv /opt/cryptpad/config/config.js /opt/
    msg_ok "Backed up configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cryptpad" "cryptpad/cryptpad" "tarball"

    msg_info "Updating CryptaPad"
    cd /opt/cryptpad
    $STD npm ci
    $STD npm run install:components
    $STD npm run build
    msg_ok "Updated CryptaPad"

    msg_info "Restoring configuration"
    mv /opt/config.js /opt/cryptpad/config/
    msg_ok "Configuration restored"

    msg_info "Starting Service"
    systemctl start cryptpad
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
