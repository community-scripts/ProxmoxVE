#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: (AminGholizad)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PanSalut/Koffan

APP="Koffan"
var_tags="${var_tags:-productivity}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /opt/koffan/koffan ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "koffan" "PanSalut/Koffan"; then
    msg_info "Stopping Service"
    systemctl stop koffan
    msg_ok "Stopped Service"

    create_backup /opt/koffan/data
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "koffan" "PanSalut/Koffan" "tarball"
    restore_backup

    msg_info "Rebuilding Koffan"
    cd /opt/koffan
    $STD go build -o koffan main.go
    msg_ok "Rebuild Koffan"

    msg_info "Starting Service"
    systemctl start koffan
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
