#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zotregistry.dev/

APP="Zot-Registry"
var_tags="${var_tags:-registry;oci}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -f /usr/bin/zot ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi

  if check_for_gh_release "zot" "project-zot/zot"; then
    msg_info "Stopping Zot service"
    systemctl stop zot
    msg_ok "Stopped Zot service"

    rm -f /usr/bin/zot
    fetch_and_deploy_gh_release "zot" "project-zot/zot" "singlefile" "latest" "/usr/bin" "zot-linux-amd64"

    msg_info "Configuring Zot Registry"
    chown root:root /usr/bin/zot
    msg_ok "Configured Zot Registry"

    msg_info "Starting service"
    systemctl start zot
    msg_ok "Service started"
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
