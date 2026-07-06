#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: ethan-hgwr
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gchq/CyberChef

APP="CyberChef"
var_tags="${var_tags:-security;data;tools}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

    if [[ ! -d /opt/cyberchef ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "cyberchef" "gchq/CyberChef"; then
        msg_info "Stopping Service"
        systemctl stop caddy
        msg_ok "Stopped Service"

        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cyberchef" "gchq/CyberChef" "tarball"

        msg_info "Building CyberChef"
        cd /opt/cyberchef
        $STD npm ci --ignore-scripts
        $STD npm run postinstall
        $STD npm run build
        msg_ok "Built CyberChef"

        msg_info "Starting Service"
        systemctl start caddy
        msg_ok "Started Service"
        msg_ok "Updated successfully!"
    fi
    exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
