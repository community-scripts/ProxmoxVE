#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Raffaele (rafspiny)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://getgrav.org/

APP="Grav"
var_tags="${var_tags:-cms}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"


header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d "/opt/grav" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "grav" "getgrav/grav"; then
        msg_info "Creating Backup"
        cd /opt/grav
        bin/grav backup -nq
        msg_ok "Backup Created"
        bin/gpm self-upgrade -y
        cd -
        chown -R www-data:www-data /opt/grav
        msg_ok "Update Successful"
    fi
    exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:80${CL}"
