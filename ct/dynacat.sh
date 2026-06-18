#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Panonim/dynacat

APP="Dynacat"
var_tags="${var_tags:-dashboard;homepage;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/dynacat/dynacat ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "dynacat" "Panonim/dynacat"; then
    msg_info "Stopping Service"
    systemctl stop dynacat
    msg_ok "Stopped Service"

    create_backup /opt/dynacat/config \
      /opt/dynacat/assets \
      /opt/dynacat/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dynacat" "Panonim/dynacat" "prebuild" "latest" "/opt/dynacat" "dynacat-linux-$(get_arch_value).tar.gz"

    restore_backup
    chmod +x /opt/dynacat/dynacat
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start dynacat
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
