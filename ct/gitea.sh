#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: Rogue-King
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://about.gitea.com/

# App Default Values
APP="Gitea"
var_tags="git"
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
   if [[ ! -f /usr/local/bin/gitea ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
   fi
   RELEASE=$(wget -q https://github.com/go-gitea/gitea/releases/latest -O - | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
   msg_info "Updating $APP to ${RELEASE}"
   wget -q https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64
   systemctl stop gitea
   rm -rf /usr/local/bin/gitea
   mv gitea* /usr/local/bin/gitea
   chmod +x /usr/local/bin/gitea
   systemctl start gitea
   msg_ok "Updated $APP Successfully"
   exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"