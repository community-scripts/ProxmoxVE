#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

APP="Kimai"
var_tags="time-tracking"
var_cpu="2"
var_ram="2048"
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
    if [[ ! -d /opt/kimai ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/kimai/kimai/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    BACKUP_DIR="/opt/kimai_backup"

    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Apache2"
        systemctl stop apache2
        msg_ok "Stopped Apache2"

        msg_info "Backing up Kimai configuration and var directory"
        mkdir -p "$BACKUP_DIR"
        [ -d /opt/kimai/var ] && cp -r /opt/kimai/var "$BACKUP_DIR/"
        [ -f /opt/kimai/.env ] && cp /opt/kimai/.env "$BACKUP_DIR/"
        [ -f /opt/kimai/config/packages/local.yaml ] && cp /opt/kimai/config/packages/local.yaml "$BACKUP_DIR/"
        msg_ok "Backup completed"

        msg_info "Updating ${APP} to ${RELEASE}"
        rm -rf /opt/kimai
        wget -q "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip"
        unzip -q ${RELEASE}.zip
        mv kimai-${RELEASE} /opt/kimai
        [ -d "$BACKUP_DIR/var" ] && cp -r "$BACKUP_DIR/var" /opt/kimai/
        [ -f "$BACKUP_DIR/.env" ] && cp "$BACKUP_DIR/.env" /opt/kimai/
        [ -f "$BACKUP_DIR/local.yaml" ] && cp "$BACKUP_DIR/local.yaml" /opt/kimai/config/packages/
        rm -rf "$BACKUP_DIR"
        cd /opt/kimai
        $STD composer install --no-dev --optimize-autoloader
        $STD bin/console kimai:update
        chown -R :www-data .
        chmod -R g+r .
        chmod -R g+rw var/
        chmod -R 777 /opt/kimai/var/
        chown -R www-data:www-data /opt/kimai
        chmod -R 755 /opt/kimai
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated ${APP} to ${RELEASE}"

        msg_info "Starting Apache2"
        systemctl start apache2
        msg_ok "Started Apache2"

        msg_info "Cleaning Up"
        rm -rf ${RELEASE}.zip
        rm -rf "$BACKUP_DIR"
        msg_ok "Cleaned"
        msg_ok "Updated Successfully"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
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
