#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hakimel/reveal.js

APP="RevealJS"
var_tags="presentation"
var_cpu="1"
var_ram="1024"
var_disk="4"
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

    if [[ ! -d "/opt/revealjs" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/hakimel/reveal.js/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop revealjs
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to ${RELEASE}"
        temp_file=$(mktemp)
        wget -q "https://github.com/hakimel/reveal.js/archive/refs/tags/${RELEASE}.tar.gz" -O $temp_file
        tar zxf $temp_file
        rm -rf /opt/revealjs/node_modules/*
        cp /opt/revealjs/index.html  /opt
        cp /opt/revealjs/gulpfile.js /opt
        cp -rf reveal.js-${RELEASE}/* /opt/revealjs
        cd /opt/revealjs
        $STD npm install
        cp -f /opt/index.html /opt/revealjs
        cp -f /opt/gulpfile.js /opt/revealjs
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated $APP to ${RELEASE}"

        msg_info "Starting $APP"
        systemctl start revealjs
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -f $temp_file
        rm -rf ~/reveal.js-${RELEASE}
        msg_ok "Cleanup Completed"

        msg_ok "Update Successful"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
