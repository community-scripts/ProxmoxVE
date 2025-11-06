#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Stroopwafe1
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://leantime.io

APP="Leantime"
var_tags="${var_tags:-productivity}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/leantime ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "leantime" "Leantime/leantime"; then
    msg_info "Creating Backup"
    mariadb-dump leantime >"/opt/${APP}_db_backup_$(date +%F).sql"
    tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" "/opt/${APP}"
    mv /opt/leantime /opt/leantime_bak
    msg_ok "Backup Created"

    fetch_and_deploy_gh_release "leantime" "Leantime/leantime" "prebuild" "latest" "/opt/leantime" Leantime*.tar.gz

    msg_info "Restoring Config & Permissions"
    mv /opt/leantime_bak/config/.env /opt/leantime/config/.env
    chown -R www-data:www-data "/opt/leantime"
    chmod -R 750 "/opt/leantime"
    msg_ok "Restored Config & Permissions"

    msg_info "Removing Backup"
    rm -rf /opt/leantime_bak
    msg_ok "Removed Backup"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/install${CL}"
