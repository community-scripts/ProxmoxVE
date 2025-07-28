#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/navidrome/navidrome

APP="Navidrome"
var_tags="${var_tags:-music}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
    if [[ ! -d /var/lib/navidrome ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    
    RELEASE=$(curl -fsSL https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat ~/.navidrome 2>/dev/null)" ]] || [[ ! -f ~/.navidrome ]]; then
        msg_info "Stopping Services"
        systemctl stop navidrome
        msg_ok "Services Stopped"

        fetch_and_deploy_gh_release "navidrome" "navidrome/navidrome" "binary"

        msg_info "Starting Services"
        systemctl start navidrome
        msg_ok "Started Services"

        msg_ok "Updated Successfully"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4533${CL}"
