#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.debian.org/

APP="PVE-Scripts-Local"
var_tags="${var_tags:-pve-scripts-local}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/ProxmoxVE-Local ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ProxmoxVE-Local" "community-scripts/ProxmoxVE-Local"; then
    msg_info "Stopping Services"
    systemctl stop pvescriptslocal
    msg_ok "Stopped Services"

    msg_info "Backup Data"
    cp /opt/ProxmoxVE-Local/.env /opt/.env.bak
    cp -r /opt/ProxmoxVE-Local/data /opt/data.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ProxmoxVE-Local" "community-scripts/ProxmoxVE-Local"

    msg_info "Restoring Data"
    if [[ -f /opt/.env.bak ]]; then
      mv /opt/.env.bak /opt/ProxmoxVE-Local/.env
    fi
    if [[ -d /opt/data.bak ]]; then
      rm -rf /opt/ProxmoxVE-Local/data
      mv /opt/data.bak /opt/ProxmoxVE-Local/data
    fi
    msg_ok "Restored Data"

    msg_info "Updating PVE Scripts local"
    cd /opt/ProxmoxVE-Local
    chmod 755 data
    $STD npm install
    $STD npm run build
    msg_ok "Updated PVE Scripts local"

    msg_info "Starting Services"
    systemctl start pvescriptslocal
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
