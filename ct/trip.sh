#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/itskovacs/TRIP

APP="TRIP"
var_tags="${var_tags:-maps;travel}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=8000
WEB_UI_PROTOCOL="http"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/trip ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "trip" "itskovacs/TRIP"; then
    msg_info "Stopping Service"
    systemctl stop trip
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "trip" "itskovacs/TRIP" "tarball"

    msg_info "Updating Frontend"
    cd /opt/trip/src
    $STD npm install
    $STD npm run build
    mkdir -p /opt/trip/frontend
    cp -r /opt/trip/src/dist/trip/browser/* /opt/trip/frontend/
    msg_ok "Updated Frontend"

    msg_info "Updating Backend"
    cd /opt/trip/backend
    $STD uv pip install --python /opt/trip/.venv/bin/python -r trip/requirements.txt
    msg_ok "Updated Backend"

    msg_info "Starting Service"
    systemctl start trip
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
