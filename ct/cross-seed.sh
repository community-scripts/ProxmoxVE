#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jakub Matraszek (jmatraszek)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.cross-seed.org

APP="cross-seed"
var_tags="arr"
var_cpu="1"
var_ram="1024"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if command -v cross-seed &> /dev/null; then
        current_version=$(cross-seed --version)
        latest_version=$(npm show cross-seed version)
        if [ "$current_version" != "$latest_version" ]; then
            msg_info "Updating ${APP} from version v${current_version} to v${latest_version}"
            npm install -g cross-seed@latest &> /dev/null
            systemctl restart cross-seed
            msg_ok "Updated Successfully"
        else
            msg_ok "${APP} is already at v${current_version}"
        fi
    else
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access cross-seed API using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2468${CL}"
