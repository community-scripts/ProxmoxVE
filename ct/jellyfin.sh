#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jellyfin.org/

# App Default Values
APP="Jellyfin"
var_tags="media"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="ubuntu"
var_version="22.04"
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
     if [[ ! -d /usr/lib/jellyfin ]]; then
          msg_error "No ${APP} Installation Found!"
          exit
     fi
     msg_info "Updating ${APP} LXC"
     apt-get update &>/dev/null
     apt-get -y upgrade &>/dev/null
     apt-get --with-new-pkgs upgrade jellyfin jellyfin-server &>/dev/null
     msg_ok "Updated ${APP} LXC"
     exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"
