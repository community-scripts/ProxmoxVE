#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/jkrgr0/ProxmoxVE/refs/heads/feature/2fauth/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: jkrgr0
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.2fauth.app/

# App Default Values
APP="2FAuth"
TAGS="2fa;authenticator"
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -d "/opt/${APP}" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -s https://api.github.com/repos/Bubka/2FAuth/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        apt-get update &>/dev/null
        apt-get -y upgrade &>/dev/null

        # Creating Backup
        msg_info "Creating Backup"
        mv "/opt/${APP}" "/opt/${APP}-backup"
        # tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" "/opt/${APP}"
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${RELEASE}"
        wget -q "https://github.com/Bubka/2FAuth/archive/refs/tags/${RELEASE}.zip"
        unzip -q "${RELEASE}.zip"
        mv "${APPLICATION}-${RELEASE}/" "/opt/${APPLICATION}"
        mv "/opt/${APP}-backup/.env" "/opt/${APP}/.env"
        mv "/opt/${APP}-backup/storage" "/opt/${APP}/storage"
        cd "/opt/${APP}" || return

        chown -R www-data: "/opt/${APP}"
        chmod -R 755 "/opt/${APP}"

        export COMPOSER_ALLOW_SUPERUSER=1
        composer install --no-dev --prefer-source &>/dev/null

        php artisan 2fauth:install
        msg_ok "Updated $APP to v${RELEASE}"

        # Cleaning up
        msg_info "Cleaning Up"
        rm -rf "/opt/v${RELEASE}.zip"
        $STD apt-get -y autoremove
        $STD apt-get -y autoclean
        msg_ok "Cleanup Completed"

        # Last Action
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"