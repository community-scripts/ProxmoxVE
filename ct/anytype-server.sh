#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://anytype.io

APP="Anytype-Server"
var_tags="${var_tags:-notes;productivity;sync}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/anytype/any-sync-bundle ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "anytype" "grishy/any-sync-bundle"; then
    msg_info "Stopping Service"
    systemctl stop anytype
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/anytype/data /opt/anytype_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "anytype" "grishy/any-sync-bundle" "prebuild" "latest" "/opt/anytype" "any-sync-bundle_*_linux_amd64.tar.gz"
    chmod +x /opt/anytype/any-sync-bundle

    msg_info "Restoring Data"
    cp -r /opt/anytype_data_backup/. /opt/anytype/data
    rm -rf /opt/anytype_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start anytype
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:33010${CL}"
echo -e "${INFO}${YW} Client config file:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}/opt/anytype/data/client-config.yml${CL}"
