#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dullage/flatnotes

APP="Flatnotes"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/flatnotes ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "flatnotes" "dullage/flatnotes"; then
    msg_info "Stopping Service"
    systemctl stop flatnotes
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration and Data"
    cp /opt/flatnotes/.env /opt/flatnotes.env
    cp -r /opt/flatnotes/data /opt/flatnotes_data_backup
    msg_ok "Backed up Configuration and Data"

    fetch_and_deploy_gh_release "flatnotes" "dullage/flatnotes"

    msg_info "Updating Flatnotes"
    cd /opt/flatnotes/client
    $STD npm install
    $STD npm run build
    cd /opt/flatnotes
    rm -f uv.lock
    $STD /usr/local/bin/uvx migrate-to-uv
    $STD /usr/local/bin/uv sync
    msg_ok "Updated Flatnotes"

    msg_info "Restoring Configuration and Data"
    cp /opt/flatnotes.env /opt/flatnotes/.env
    cp -r /opt/flatnotes_data_backup/. /opt/flatnotes/data
    rm -f /opt/flatnotes.env
    rm -r /opt/flatnotes_data_backup
    msg_ok "Restored Configuration and Data"

    msg_info "Starting Service"
    systemctl start flatnotes
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

