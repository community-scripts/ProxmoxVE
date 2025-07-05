#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dashy.to/

APP="Dashy"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/dashy/public/ ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/Lissy93/dashy/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  if [[ "${RELEASE}" != "$(cat ~/.dashy 2>/dev/null)" ]] || [[ ! -f ~/.dashy ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop dashy
    msg_ok "Stopped ${APP}"

    msg_info "Backing up conf.yml"
    cd ~
    if [[ -f /opt/dashy/public/conf.yml ]]; then
      cp -R /opt/dashy/public/conf.yml conf.yml
    else
      cp -R /opt/dashy/user-data/conf.yml conf.yml
    fi
    msg_ok "Backed up conf.yml"

    rm -rf /opt/dashy
    fetch_and_deploy_gh_release "dashy" "Lissy93/dashy"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt/dashy
    npm install
    npm run build
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Restoring conf.yml"
    cd ~
    cp -R conf.yml /opt/dashy/user-data
    msg_ok "Restored conf.yml"

    msg_info "Cleaning"
    rm -rf conf.yml /opt/dashy/public/conf.yml
    msg_ok "Cleaned"

    msg_info "Starting Dashy"
    systemctl start dashy
    msg_ok "Started Dashy"

    msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4000${CL}"
