#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gogs.io/

APP="Gogs"
var_tags="${var_tags:-git;code;devops}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -f /opt/gogs/gogs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "gogs" "gogs/gogs"; then
    msg_info "Stopping Service"
    systemctl stop gogs
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/gogs/custom /opt/gogs_custom_backup
    cp -r /opt/gogs/data /opt/gogs_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gogs" "gogs/gogs" "prebuild" "latest" "/opt/gogs" "gogs_*_linux_amd64.tar.gz"

    msg_info "Restoring Data"
    cp -r /opt/gogs_custom_backup/. /opt/gogs/custom
    cp -r /opt/gogs_data_backup/. /opt/gogs/data
    rm -rf /opt/gogs_custom_backup /opt/gogs_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start gogs
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
