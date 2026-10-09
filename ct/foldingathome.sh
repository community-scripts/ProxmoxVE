#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | Co-Author: 007hacky007
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FoldingAtHome/fah-client-bastet

APP="FoldingAtHome"
var_tags="${var_tags:-science;distributed-computing}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_gpu="${var_gpu:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_fah_token="${var_fah_token:-}"
export var_fah_machine_name="${var_fah_machine_name:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/bin/fah-client ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  fetch_and_deploy_from_url "https://download.foldingathome.org/releases/public/fah-client/$(arch_resolve "debian-10-64bit" "debian-stable-arm64")/release/latest.deb"
  msg_ok "Folding@home is at $(dpkg-query -W -f='${Version}' fah-client)"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Manage it from the Folding@home Web Control:${CL}"
echo -e "${GATEWAY}${BGN}https://app.foldingathome.org/${CL}"
echo -e "${INFO}${YW}The client starts paused - press Fold once the machine shows up in your account${CL}"
echo -e "${INFO}${YW}Account token and machine name are in /etc/fah-client/config.xml${CL}"
