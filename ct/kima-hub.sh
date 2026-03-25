#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Chevron7Locked/kima-hub

APP="Kima-Hub"
var_tags="${var_tags:-music;streaming;media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/kima-hub ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kima-hub" "Chevron7Locked/kima-hub"; then
    msg_info "Stopping Services"
    systemctl stop kima-frontend kima-backend kima-analyzer kima-analyzer-clap
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/kima-hub/backend/.env /opt/kima-hub-backend-env.bak
    cp /opt/kima-hub/frontend/.env /opt/kima-hub-frontend-env.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kima-hub" "Chevron7Locked/kima-hub" "tarball"

    msg_info "Restoring Data"
    cp /opt/kima-hub-backend-env.bak /opt/kima-hub/backend/.env
    cp /opt/kima-hub-frontend-env.bak /opt/kima-hub/frontend/.env
    rm -f /opt/kima-hub-backend-env.bak /opt/kima-hub-frontend-env.bak
    msg_ok "Restored Data"

    msg_info "Rebuilding Backend"
    cd /opt/kima-hub/backend
    $STD npm install
    $STD npm run build
    $STD npx prisma generate
    $STD npx prisma migrate deploy
    msg_ok "Rebuilt Backend"

    msg_info "Rebuilding Frontend"
    cd /opt/kima-hub/frontend
    $STD npm install
    $STD npm run build
    msg_ok "Rebuilt Frontend"

    msg_info "Starting Services"
    systemctl start kima-backend kima-frontend kima-analyzer kima-analyzer-clap
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3030${CL}"
