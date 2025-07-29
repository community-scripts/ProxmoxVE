#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.inspircd.org/

APP="InspIRCd"
var_tags="${var_tags:-IRC}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -f /lib/systemd/system/inspircd.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/inspircd/inspircd/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.inspircd 2>/dev/null)" ]] || [[ ! -f ~/.inspircd ]]; then
    msg_info "Stopping Service"
    systemctl stop inspircd
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "inspircd" "inspircd/inspircd" "binary"

    msg_info "Starting Service"
    systemctl start inspircd
    msg_ok "Started Service"

    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Server-Acces it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:6667${CL}"
