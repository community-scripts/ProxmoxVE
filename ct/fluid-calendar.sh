#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fluidcalendar.com

APP="fluid-calendar"
var_tags="calendar,tasks"
var_cpu="3"
var_ram="4096"
var_disk="7"
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

    if [[ ! -d /opt/fluid-calendar ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/dotnetfactory/fluid-calendar/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop fluid-calendar.service
        msg_ok "Stopped $APP"

        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /opt/fluid-calendar
        msg_ok "Backup Created"

        msg_info "Updating $APP to v${RELEASE}"
        tmp_file=$(mktemp)
        wget -q "https://github.com/dotnetfactory/fluid-calendar/archive/refs/tags/v${RELEASE}.zip" -O $tmp_file
        unzip -q $tmp_file
        cp -rf ${APP}-${RELEASE}/* /opt/fluid-calendar
        cd /opt/fluid-calendar
        export NEXT_TELEMETRY_DISABLED=1
        $STD npm install --legacy-peer-deps
        $STD npm run prisma:generate
        $STD npx prisma migrate deploy
        $STD npm run build:os
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start fluid-calendar.service
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf $tmp_file
        rm -rf "/opt/${APP}_backup_$(date +%F).tar.gz"
        rm -rf /tmp/${APP}-${RELEASE}
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
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
