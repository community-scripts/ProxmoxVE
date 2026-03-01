#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joerg Heinemann (heinemannj)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/john30/ebusd

APP="ebusd"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -f /etc/default/ebusd ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "ebusd" "john30/ebusd"; then
    msg_info "Stopping Services"
    systemctl stop ebusd
    msg_ok "Stopped Services"

    fetch_and_deploy_gh_release "ebusd" "john30/ebusd" "binary" "latest" "/opt/ebusd" "ebusd-*_amd64-trixie_mqtt1.deb"

    msg_info "Starting Services"
    systemctl start ebusd
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
