#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://vikunja.io/

APP="Vikunja"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/vikunja ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://dl.vikunja.io/vikunja/ | grep -oP 'href="/vikunja/\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop vikunja
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt || exit
    rm -rf /opt/vikunja/vikunja
    curl -fsSL "https://dl.vikunja.io/vikunja/$RELEASE/vikunja-$RELEASE-amd64.deb" -o $(basename "https://dl.vikunja.io/vikunja/$RELEASE/vikunja-$RELEASE-amd64.deb")
    export DEBIAN_FRONTEND=noninteractive
    $STD dpkg -i vikunja-"$RELEASE"-amd64.deb
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start vikunja
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -rf /opt/vikunja-"$RELEASE"-amd64.deb
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3456${CL}"
