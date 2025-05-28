#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/

APP="ProjectSend"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/projectsend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/projectsend/projectsend/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    curl -fsSL "https://github.com/projectsend/projectsend/releases/download/r${RELEASE}/projectsend-r${RELEASE}.zip" -o $(basename "https://github.com/projectsend/projectsend/releases/download/r${RELEASE}/projectsend-r${RELEASE}.zip")
    $STD unzip -o "projectsend-r${RELEASE}.zip" -d projectsend
    chown -R www-data:www-data /opt/projectsend
    chmod -R 775 /opt/projectsend
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf "/opt/projectsend-r${RELEASE}.zip"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
