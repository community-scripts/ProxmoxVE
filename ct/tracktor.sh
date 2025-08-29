#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tracktor.bytedge.in/

APP="tracktor"
var_tags="${var_tags:-car;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/tracktor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "tracktor" "javedh-dev/tracktor"; then
    msg_info "Stopping Service"
    systemctl stop tracktor
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/tracktor/app/backend/.env /opt/tracktor.env
    msg_ok "Created Backup"

    setup_nodejs
    fetch_and_deploy_gh_release "tracktor" "javedh-dev/tracktor" "tarball" "latest" "/opt/tracktor"

    msg_info "Updating ${APP}"
    cd /opt/tracktor
    $STD npm install
    $STD npm run build
    msg_ok "Updated $APP"

    msg_info "Restoring Backup"
    cp /opt/tracktor.env /opt/tracktor/app/backend/.env
    msg_ok "Restored Backup"

    msg_info "Starting Service"
    systemctl start tracktor
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
