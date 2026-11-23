#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Marcos Felipe (mfelipe)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/volcengine/OpenViking

APP="OpenViking"
var_tags="${var_tags:-ai;memory;rag}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/openviking ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating Debian Packages"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated Debian Packages"

  if check_for_gh_release "openviking-server" "volcengine/OpenViking"; then
    msg_info "Stopping Service"
    systemctl stop openviking
    msg_ok "Stopped Service"

    msg_info "Updating OpenViking"
    $STD uv pip install --python /opt/openviking/bin/python --upgrade openviking
    msg_ok "Updated OpenViking"

    msg_info "Starting Service"
    systemctl start openviking
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1933/studio${CL}"
