#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://certimate.me/

APP="Certimate"
var_tags="${var_tags:-ssl;certificates;acme;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/certimate/certimate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "certimate" "certimate-go/certimate"; then
    msg_info "Stopping Service"
    systemctl stop certimate
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/certimate/pb_data /opt/certimate_pb_data_backup
    msg_ok "Backed up Data"

    fetch_and_deploy_gh_release "certimate" "certimate-go/certimate" "prebuild" "latest" "/opt/certimate" "certimate_*_linux_amd64.zip"

    msg_info "Restoring Data"
    cp -r /opt/certimate_pb_data_backup/. /opt/certimate/pb_data
    rm -rf /opt/certimate_pb_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start certimate
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
