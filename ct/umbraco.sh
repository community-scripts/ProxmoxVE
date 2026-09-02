#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joost van den Berg (montagneId)
# License: MIT | https://github.com/montagneid/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/umbraco/Umbraco-CMS

APP="Umbraco"
var_tags="${var_tags:-website}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
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
    if [[ ! -d /var/www ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating LXC"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Updated LXC"
    
    msg_info "Updating Umbraco Templates"
    $STD dotnet new update
    msg_ok "Updated Umbraco Templates"
    exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}"
