#!/usr/bin/env bash
# shellcheck disable=SC1090
source <(curl -s https://raw.githubusercontent.com/fabrice1236/ProxmoxVE/refs/heads/ghost-testing/misc/build.func) 
# Copyright (c) 2021-2025 community-scripts ORG
# Author: fabrice1236
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghost.org/

# App Default Values
APP="Ghost"
var_tags="cms;blog"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="ubuntu"
var_version="20.04"
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
    msg_info "Updating ${APP} LXC"
    # CHECK FOR NPM HERE !  

    if command -v ghost &> /dev/null; then
        current_version=$(ghost --version | awk '{print $2}') #TO REVIEW
        latest_version=$(npm show ghost-cli version)
        if [ "$current_version" != "$latest_version" ]; then
            msg_info "Updating ${APP} from version $current_version to $latest_version"
            npm install -g ghost-cli@latest &> /dev/null
        else
            msg_ok "${APP} is already up-to-date (version $current_version)"
        fi
    else
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

# Ensure the container is created before starting it
if pct status "$CT_ID" &>/dev/null; then
  msg_info "Starting LXC Container"
  pct start "$CT_ID"
  msg_ok "Started LXC Container"
else
  msg_error "Failed to create LXC Container"
  exit 1
fi

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"