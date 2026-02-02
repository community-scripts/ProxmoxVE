#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

APP="Alpine-RustyPaste"
var_tags="${var_tags:-alpine;pastebin;storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-4}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if ! apk info -e rustypaste >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating RustyPaste"
  $STD apk update
  $STD apk upgrade rustypaste --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  msg_ok "Updated RustyPaste"

  msg_info "Restarting Services"
  $STD rc-service rustypaste restart
  msg_ok "Restarted Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
