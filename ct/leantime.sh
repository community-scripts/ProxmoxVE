#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stroopwafe1
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://leantime.io | Github: https://github.com/Leantime/leantime

APP="Leantime"
var_tags="${var_tags:-productivity}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/leantime ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "leantime" "Leantime/leantime"; then
    create_backup /opt/leantime

    fetch_and_deploy_gh_release "leantime" "Leantime/leantime" "prebuild" "latest" "/opt/leantime" Leantime*.tar.gz
    restore_backup


    msg_info "Removing Backup"
    msg_ok "Removed Backup"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}/install${CL}"
