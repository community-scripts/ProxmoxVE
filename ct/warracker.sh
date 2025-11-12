#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: BvdBerg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sassanix/Warracker/

APP="Warracker"
var_tags="${var_tags:-warranty}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
    if [[ ! -d /opt/warracker ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if check_for_gh_release "warracker" "sassanix/Warracker"; then
        msg_info "Stopping Services"
        systemctl stop warrackermigration
        systemctl stop warracker
        systemctl stop nginx
        msg_ok "Stopped Services"

        fetch_and_deploy_gh_release "warracker" "sassanix/Warracker" "tarball" "latest" "/opt/warracker"

        msg_info "Updating Warracker"
        cd /opt/warracker/backend
        $STD uv venv .venv
        $STD source .venv/bin/activate
        $STD uv pip install -r requirements.txt
        msg_ok "Updated Warracker"

        msg_info "Starting Services"
        systemctl start warracker
        systemctl start nginx
        msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
