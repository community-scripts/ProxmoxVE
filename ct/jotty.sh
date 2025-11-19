#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/jotty

APP="jotty"
var_tags="${var_tags:-tasks;notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  if [[ ! -d /opt/jotty ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "jotty" "fccview/jotty"; then
    msg_info "Stopping Service"
    systemctl stop jotty
    msg_ok "Stopped Service"

    msg_info "Backing up configuration & data"
    cd /opt/jotty
    cp ./.env /opt/app.env
    $STD tar -cf /opt/data_config.tar ./data ./config
    msg_ok "Backed up configuration & data"

    NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jotty" "fccview/jotty" "tarball" "latest" "/opt/jotty"

    msg_info "Updating jotty"
    cd /opt/jotty
    $STD yarn --frozen-lockfile
    $STD yarn next telemetry disable
    $STD yarn build
    msg_ok "Updated jotty"

    msg_info "Restoring configuration & data"
    mv /opt/app.env /opt/jotty/.env
    $STD tar -xf /opt/data_config.tar
    msg_ok "Restored configuration & data"

    msg_info "Starting Service"
    systemctl start jotty
    msg_ok "Started Service"
    rm /opt/data_config.tar
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
