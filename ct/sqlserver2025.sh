#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.microsoft.com/en-us/sql-server/sql-server-2025

APP="SQL Server 2025"
var_tags="${var_tags:-sql;database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/mssql ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating SQL Server 2025"
    rm -f /etc/profile.d/debuginfod.sh /etc/profile.d/debuginfod.csh
    $STD apt update
    $STD apt -y upgrade
    msg_ok "Updated successfully!"
    exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:1433${CL}"
