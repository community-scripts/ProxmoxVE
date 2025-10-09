#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/rwMarkable

APP="rwMarkable"
var_tags="${var_tags:-tasks;notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/rwmarkable ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rwMarkable" "fccview/rwMarkable"; then
    msg_info "Stopping ${APP}"
    systemctl stop rwmarkable
    msg_ok "Stopped ${APP}"

    msg_info "Backing up configuration & data"
    cd /opt/rwmarkable
    cp ./.env /opt/app.env
    $STD tar -cf /opt/data_config.tar ./data ./config
    msg_ok "Backed up configuration & data"

    NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rwMarkable" "fccview/rwMarkable" "tarball" "latest" "/opt/rwmarkable"

    msg_info "Updating app"
    cd /opt/rwmarkable
    $STD yarn --frozen-lockfile
    $STD yarn next telemetry disable
    $STD yarn build
    msg_ok "Updated app"

    msg_info "Restoring configuration & data"
    mv /opt/app.env /opt/rwmarkable/.env
    $STD tar -xf /opt/data_config.tar
    msg_ok "Restored configuration & data"

    msg_info "Restarting ${APP} service"
    systemctl start rwmarkable
    msg_ok "Restarted ${APP} service"
    rm /opt/data_config.tar
    msg_ok "Updated Successfully"
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
