#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://stonith404.github.io/pingvin-share/introduction

# App Default Values
APP="Pingvin"
var_tags="sharing"
var_cpu="2"
var_ram="2048"
var_disk="8"
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
    if [[ ! -d /opt/pingvin-share ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
   
    RELEASE=$(curl -s https://api.github.com/repos/stonith404/pingvin-share/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/pingvin_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/pingvin_version.txt)" ]]; then
      
      msg_info "Stopping Pingvin Share"
      systemctl stop pm2-root.service
      msg_ok "Stopped Pingvin Share"
      
      msg_info "Updating Pingvin Share to v${RELEASE}"
      cd /opt
      wget -q "https://github.com/stonith404/pingvin-share/archive/refs/tags/v${RELEASE}.zip"
      unzip -q v${RELEASE}.zip
      mv pingvin-share-${RELEASE} /opt/pingvin-share  
      cd /opt/pingvin-share
      cd backend
      npm install &>/dev/null
      npm run build &>/dev/null
      cd ../frontend
      npm install &>/dev/null
      npm run build &>/dev/null
      echo "${RELEASE}" >"/opt/pingvin_version.txt"
      rm -rf /opt/v${RELEASE}.zip
      msg_ok "Updated Pingvin Share to v${RELEASE}"

      msg_info "Starting Pingvin Share"
      systemctl start pm2-root.service
      msg_ok "Started Pingvin Share"

      msg_ok "Updated Successfully"
      exit
  else
    msg_ok "No update required. Pingvin Share is already at v${RELEASE}."
  fi
}


start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
