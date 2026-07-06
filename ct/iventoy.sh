#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.iventoy.com/en/index.html

APP="iVentoy"
var_tags="${var_tags:-pxe-tool}"
var_disk="${var_disk:-2}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/iventoy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "iventoy" "ventoy/PXE"; then
    msg_info "Stopping iVentoy"
    $STD /opt/iventoy/iventoy.sh stop
    msg_ok "Stopped iVentoy"

    create_backup /opt/iventoy/data /opt/iventoy/iso
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "iventoy" "ventoy/PXE" "prebuild" "latest" "/opt/iventoy" "iventoy-*-linux-$(arch_resolve x86_64-free arm64-trial).tar.gz"
    restore_backup

    msg_info "Starting iVentoy"
    $STD /opt/iventoy/iventoy.sh -R start
    msg_ok "Started iVentoy"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:26000${CL}"
