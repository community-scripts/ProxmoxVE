#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com

APP="Tududi"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/tududi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "tududi" "chrisvel/tududi"; then
    msg_info "Stopping Service"
    systemctl stop tududi
    msg_ok "Stopped Service"

    msg_info "Remove and backup Files"
    cp /opt/tududi/backend/.env /opt/tududi.env
    rm -rf /opt/tududi/backend/dist
    msg_ok "Backup and removed Files"

    fetch_and_deploy_gh_release "tududi" "chrisvel/tududi"

    msg_info "Updating ${APP}"
    cd /opt/tududi
    $STD npm install
    export NODE_ENV=production
    $STD npm run frontend:build
    mv ./dist ./backend
    mv ./public/locales ./backend/dist
    mv ./public/favicon.* ./backend/dist
    mv /opt/tududi.env /opt/tududi/.env
    msg_ok "Updated $APP"

    msg_info "Starting Service"
    systemctl start tududi
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3002${CL}"
