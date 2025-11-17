#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lissy93/domain-locker

APP="Domain-Locker"
var_tags="${var_tags:-Monitoring}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
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
    if [[ ! -d /opt/domain-locker ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "domain-locker" "Lissy93/domain-locker"; then
        msg_info "Stopping Service"
        systemctl stop domain-locker
        msg_info "Service stopped"

        PG_VERSION="17" setup_postgresql
        setup_nodejs
        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "domain-locker" "Lissy93/domain-locker"

        msg_info "Installing Modules (patience)"
        cd /opt/domain-locker
        $STD npm install
        msg_ok "Installed Modules"

        msg_info "Building Domain-Locker (a lot of patience)"
        set -a
        source /opt/domain-locker.env
        set +a
        $STD npm run build
        msg_info "Built Domain-Locker"

        msg_info "Restarting Services"
        systemctl start domain-locker
        msg_ok "Restarted Services"
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
