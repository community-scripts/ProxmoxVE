#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mauriceboe/TREK

APP="TREK"
var_tags="${var_tags:-travel;planning;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/trek ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "trek" "mauriceboe/TREK"; then
    msg_info "Stopping Service"
    systemctl stop trek
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/trek/server/.env /opt/trek.env.bak
    mv /opt/trek/data /opt/trek-data.bak
    mv /opt/trek/uploads /opt/trek-uploads.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "trek" "mauriceboe/TREK" "tarball"

    msg_info "Building Client"
    cd /opt/trek/client
    $STD npm ci
    $STD npm run build
    mkdir -p /opt/trek/server/public
    cp -r /opt/trek/client/dist/* /opt/trek/server/public/
    cp -r /opt/trek/client/public/fonts /opt/trek/server/public/fonts 2>/dev/null || true
    msg_ok "Built Client"

    msg_info "Installing Server Dependencies"
    cd /opt/trek/server
    $STD npm ci
    msg_ok "Installed Server Dependencies"

    msg_info "Restoring Data"
    mv /opt/trek-data.bak /opt/trek/data
    mv /opt/trek-uploads.bak /opt/trek/uploads
    rm -rf /opt/trek/server/data /opt/trek/server/uploads
    ln -s /opt/trek/data /opt/trek/server/data
    ln -s /opt/trek/uploads /opt/trek/server/uploads
    cp /opt/trek.env.bak /opt/trek/server/.env
    rm -f /opt/trek.env.bak
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start trek
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
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
