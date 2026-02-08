#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bzumhagen
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Wetzel402/Skylite-UX

APP="Skylite-UX"
var_tags="${var_tags:-family;productivity}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/skylite-ux ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "skylite-ux" "Wetzel402/Skylite-UX"; then
    msg_info "Stopping Service"
    systemctl stop skylite-ux
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/skylite-ux/.env /tmp/skylite-ux.env.backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "skylite-ux" "Wetzel402/Skylite-UX" "tarball"

    msg_info "Restoring Data"
    cp /tmp/skylite-ux.env.backup /opt/skylite-ux/.env
    rm -f /tmp/skylite-ux.env.backup
    msg_ok "Restored Data"

    msg_info "Building Skylite-UX"
    cd /opt/skylite-ux
    $STD npm ci
    $STD npx prisma generate
    $STD npm run build
    msg_ok "Built Skylite-UX"

    msg_info "Running Database Migrations"
    cd /opt/skylite-ux
    $STD npx prisma migrate deploy
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start skylite-ux
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
