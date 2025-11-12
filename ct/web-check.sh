#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lissy93/web-check

APP="web-check"
var_tags="${var_tags:-network;analysis}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/web-check ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "web-check" "CrazyWolf13/web-check"; then
    msg_info "Stopping Service"
    systemctl stop web-check
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/web-check/.env /opt
    msg_ok "Created backup"

    NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "web-check" "CrazyWolf13/web-check"

    msg_info "Restoring backup"
    mv /opt/.env /opt/web-check
    msg_ok "Restored backup"

    msg_info "Building Web-Check"
    cd /opt/web-check
    $STD yarn install --frozen-lockfile --network-timeout 100000
    $STD yarn build --production
    $STD npm cache clean --force
    msg_ok "Built Web-Check"

    msg_info "Starting Service"
    systemctl start web-check
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
