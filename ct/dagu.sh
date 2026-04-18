#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dagu.sh/

APP="Dagu"
var_tags="${var_tags:-automation;workflow;scheduler}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -f /opt/dagu/dagu ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "dagu" "dagucloud/dagu"; then
    msg_info "Stopping Service"
    systemctl stop dagu
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/dagu/data /opt/dagu_data_backup
    msg_ok "Backed up Data"

    fetch_and_deploy_gh_release "dagu" "dagucloud/dagu" "prebuild" "latest" "/opt/dagu" "dagu_*_linux_amd64.tar.gz"

    msg_info "Restoring Data"
    mkdir -p /opt/dagu/data
    cp -r /opt/dagu_data_backup/. /opt/dagu/data
    rm -rf /opt/dagu_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start dagu
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
