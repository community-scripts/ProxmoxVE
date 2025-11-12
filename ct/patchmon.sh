#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatchMon/PatchMon

APP="PatchMon"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d "/opt/patchmon" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs
  if check_for_gh_release "PatchMon" "PatchMon/PatchMon"; then
    msg_info "Stopping Service"
    systemctl stop patchmon-server
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/patchmon/backend/.env /opt/backend.env
    cp /opt/patchmon/frontend/.env /opt/frontend.env
    msg_ok "Backup Created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "tarball" "latest" "/opt/patchmon"

    msg_info "Updating PatchMon"
    cd /opt/patchmon
    export NODE_ENV=production
    $STD npm install --no-audit --no-fund --no-save --ignore-scripts
    cd /opt/patchmon/backend
    $STD npm install --no-audit --no-fund --no-save --ignore-scripts
    cd /opt/patchmon/frontend
    $STD npm install --include=dev --no-audit --no-fund --no-save --ignore-scripts
    $STD npm run build
    cd /opt/patchmon/backend
    mv /opt/backend.env /opt/patchmon/backend/.env
    mv /opt/frontend.env /opt/patchmon/frontend/.env
    $STD npx prisma migrate deploy
    $STD npx prisma generate
    msg_ok "Updated PatchMon"

    msg_info "Starting Service"
    systemctl start patchmon-server
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
