#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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
    if [[ ! -d "/opt/2fauth" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -s https://api.github.com/repos/Bubka/2FAuth/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/2fauth_version.txt)" ]] || [[ ! -f /opt/2fauth_version.txt ]]; then
        msg_info "Updating $APP to ${RELEASE}"

        apt-get update &>/dev/null
        apt-get -y upgrade &>/dev/null

        # Creating Backup
        msg_info "Creating Backup"
        mv "/opt/2fauth" "/opt/2fauth-backup"
        msg_ok "Backup Created"

        # Execute Update
        wget -q "https://github.com/Bubka/2FAuth/archive/refs/tags/${RELEASE}.zip"
        unzip -q "${RELEASE}.zip"
        mv "2FAuth-${RELEASE//v}/" "/opt/2fauth"
        mv "/opt/2fauth-backup/.env" "/opt/2fauth/.env"
        mv "/opt/2fauth-backup/storage" "/opt/2fauth/storage"
        cd "/opt/2fauth" || return

        chown -R www-data: "/opt/2fauth"
        chmod -R 755 "/opt/2fauth"

        export COMPOSER_ALLOW_SUPERUSER=1
        composer install --no-dev --prefer-source &>/dev/null

        php artisan 2fauth:install

        # Cleaning up
        msg_info "Cleaning Up"
        rm -rf "v${RELEASE}.zip"
        $STD apt-get -y autoremove
        $STD apt-get -y autoclean
        msg_ok "Cleanup Completed"

        # Last Action
        echo "${RELEASE}" >/opt/2fauth_version.txt
        msg_ok "Updated $APP to ${RELEASE}"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"