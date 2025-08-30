#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pocketbase.io/

APP="Pocketbase"
var_tags="${var_tags:-database}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/pocketbase.service || ! -x /opt/pocketbase/pocketbase ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "pocketbase" "pocketbase/pocketbase"; then
    msg_info "Stopping ${APP}"
    systemctl stop pocketbase
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    /opt/pocketbase/pocketbase update
    echo "${CHECK_UPDATE_RELEASE}" >~/.pocketbase
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start pocketbase
    msg_ok "Started ${APP}"
    msg_ok "Update Successful"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/_/${CL}"
