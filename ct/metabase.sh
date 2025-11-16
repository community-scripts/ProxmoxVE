#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.metabase.com/

APP="Metabase"
var_tags="${var_tags:-analytics}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
    if [[ ! -d /opt/metabase ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "metabase" "metabase/metabase"; then
        msg_info "Stopping Service"
        systemctl stop metabase
        msg_info "Stopped Service"

        msg_info "Creating backup"
        mv /opt/metabase/.env /opt
        msg_ok "Created backup"

        msg_info "Updating Metabase"
        RELEASE=$(get_latest_github_release "metabase/metabase")
        curl -fsSL "https://downloads.metabase.com/v${RELEASE}.x/metabase.jar" -o /opt/metabase/metabase.jar
        echo $RELEASE >~/.metabase
        msg_ok "Updated Metabase"

        msg_info "Restoring backup"
        mv /opt/.env /opt/metabase
        msg_ok "Restored backup"

        msg_info "Starting Service"
        systemctl start metabase
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
