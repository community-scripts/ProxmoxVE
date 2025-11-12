#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: omernaveedxyz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://miniflux.app/

APP="Miniflux"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -f /etc/systemd/system/miniflux.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  $STD miniflux -flush-sessions -config-file /etc/miniflux.conf
  systemctl stop miniflux
  msg_ok "Service Stopped"

  fetch_and_deploy_gh_release "miniflux" "miniflux/v2" "binary" "latest"
  
  msg_info "Updating Miniflux"
  $STD miniflux -migrate -config-file /etc/miniflux.conf
  msg_ok "Updated Miniflux"
  msg_info "Starting Service"
  $STD systemctl start miniflux
  msg_ok "Started Service"
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
