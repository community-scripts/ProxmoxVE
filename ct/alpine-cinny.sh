#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tobias Salzmann (Eun)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cinnyapp/cinny

APP="Alpine-Cinny"
var_tags="${var_tags:-alpine;matrix}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info

    if [[ ! -d /opt/cinny ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "cinny" "cinnyapp/cinny"; then
        msg_info "Backing up Configuration"
        cp /opt/cinny/config.json /opt/cinny_config.json.bak
        msg_ok "Backed up Configuration"

        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cinny" "cinnyapp/cinny" "prebuild" "latest" "/opt/cinny" "cinny-*.tar.gz"

        msg_info "Restoring Configuration"
        cp /opt/cinny_config.json.bak /opt/cinny/config.json
        rm -f /opt/cinny_config.json.bak
        msg_ok "Restored Configuration"

        msg_info "Restarting nginx"
        $STD rc-service nginx restart
        msg_ok "Updated successfully!"
    fi
    exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following IP:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
