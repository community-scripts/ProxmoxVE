#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Pouzor/homelable

APP="Homelable"
var_tags="${var_tags:-monitoring;network;visualization}"
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

  if [[ ! -d /opt/homelable ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "homelable" "Pouzor/homelable"; then
    msg_info "Stopping Service"
    systemctl stop homelable
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration and Data"
    cp /opt/homelable/backend/.env /opt/homelable.env.bak
    cp -r /opt/homelable/data /opt/homelable_data_bak
    msg_ok "Backed up Configuration and Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "homelable" "Pouzor/homelable" "tarball" "latest" "/opt/homelable"

    msg_info "Updating Python Dependencies"
    cd /opt/homelable/backend
    $STD uv venv --clear /opt/homelable/backend/.venv
    $STD uv pip install --python /opt/homelable/backend/.venv/bin/python -r requirements.txt
    msg_ok "Updated Python Dependencies"

    msg_info "Rebuilding Frontend"
    cd /opt/homelable/frontend
    $STD npm ci
    $STD npm run build
    msg_ok "Rebuilt Frontend"

    msg_info "Restoring Configuration and Data"
    cp /opt/homelable.env.bak /opt/homelable/backend/.env
    cp -r /opt/homelable_data_bak/. /opt/homelable/data/
    rm -f /opt/homelable.env.bak
    rm -rf /opt/homelable_data_bak
    msg_ok "Restored Configuration and Data"

    msg_info "Starting Service"
    systemctl start homelable
    msg_ok "Started Service"
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
