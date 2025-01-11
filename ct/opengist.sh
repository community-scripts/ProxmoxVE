#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/jd-apprentice/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

# App Default Values
APP="Opengist"
var_tags="development"
var_cpu="1"
var_ram="1024"
var_disk="8"
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
    if [[ ! -f /usr/local/bin/opengist ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP} LXC"
    LATEST_URL=$(curl -s https://api.github.com/repos/thomiceli/opengist/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64.tar.gz")).browser_download_url')
    wget "$LATEST_URL"
    mv opengist*.tar.gz opengist.tar.gz
    tar -xf opengist.tar.gz
    mv opengist/opengist /opt/opengist/opengist
    mv opengist/config.yml /opt/opengist/config.yml
    chmod +x /usr/local/bin/opengist
    rm -rf opengist*
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6157${CL}"