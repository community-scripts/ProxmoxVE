#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lobehub/lobehub

APP="LobeHub"
var_tags="${var_tags:-ai;chat}"
var_cpu="${var_cpu:-6}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d /opt/lobehub ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "lobehub" "lobehub/lobehub"; then
    msg_info "Stopping Services"
    systemctl stop lobehub
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/lobehub/.env /opt/lobehub.env.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lobehub" "lobehub/lobehub" "tarball"

    msg_info "Restoring Configuration"
    cp /opt/lobehub.env.bak /opt/lobehub/.env
    rm -f /opt/lobehub.env.bak
    msg_ok "Restored Configuration"

    msg_info "Building Application"
    cd /opt/lobehub
    export NODE_OPTIONS="--max-old-space-size=8192"
    $STD pnpm install
    $STD pnpm run build:docker
    unset NODE_OPTIONS
    msg_ok "Built Application"

    msg_info "Running Database Migrations"
    cd /opt/lobehub
    set -a && source /opt/lobehub/.env && set +a
    $STD node /opt/lobehub/.next/standalone/docker.cjs
    msg_ok "Ran Database Migrations"

    msg_info "Starting Services"
    systemctl start lobehub
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3210${CL}"
