#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pairdrop.net/

APP="PairDrop"
var_tags="${var_tags:-sharing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
    if [[ ! -d /opt/pairdrop ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/schlagmichdoch/PairDrop/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f ~/.pairdrop ]] || [[ "${RELEASE}" != "$(cat ~/.pairdrop)" ]]; then
      msg_info "Stopping ${APP}"
      systemctl stop pairdrop
      msg_ok "Stopped ${APP}"
      
      fetch_and_deploy_gh_release "pairdrop" "schlagmichdoch/PairDrop" "tarball"

      msg_info "Configuring PairDrop"
      cd /opt/pairdrop
      $STD npm install
      msg_ok "Configured PairDrop"

      msg_info "Starting ${APP}"
      systemctl start pairdrop
      msg_ok "Started ${APP}"

      msg_ok "Updated Successfully"
    else
      msg_ok "No update required. ${APP} is already at ${RELEASE}."
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
