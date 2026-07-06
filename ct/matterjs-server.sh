#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matter-js/matterjs-server

APP="MatterJS-Server"
var_tags="${var_tags:-matter;iot;smarthome;homeassistant}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

    if [[ ! -d /opt/matter-server ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    NODE_VERSION="24" setup_nodejs

    CURRENT=$(cat /opt/matter-server/node_modules/matter-server/package.json | grep '"version"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    LATEST=$(npm view matter-server version 2>/dev/null)
    if [[ "$CURRENT" != "$LATEST" ]]; then
        msg_info "Stopping Service"
        systemctl stop matterjs-server
        msg_ok "Stopped Service"

        msg_info "Updating ${APP} from v${CURRENT} to v${LATEST}"
        cd /opt/matter-server
        $STD npm install matter-server@latest
        msg_ok "Updated ${APP}"

        msg_info "Starting Service"
        systemctl start matterjs-server
        msg_ok "Started Service"
        msg_ok "Updated successfully!"
    else
        msg_ok "No update required. ${APP} is already at v${LATEST}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5580${CL}"
