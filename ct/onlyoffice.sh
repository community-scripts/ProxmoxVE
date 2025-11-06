#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.onlyoffice.com/

APP="ONLYOFFICE"
var_tags="${var_tags:-word;excel;powerpoint;pdf}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /var/www/onlyoffice ]]; then
    msg_error "No valid ${APP} installation found!"
    exit
  fi

  msg_info "Updating $APP"
  $STD apt update
  $STD apt -y --only-upgrade install onlyoffice-documentserver
  msg_ok "Updated $APP"

  if systemctl is-enabled --quiet onlyoffice-documentserver; then
    msg_info "Restarting $APP"
    $STD systemctl restart onlyoffice-documentserver
    msg_ok "$APP restarted"
  fi
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
