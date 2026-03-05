#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/papra-hq/papra

APP="Papra"
var_tags="${var_tags:-document-management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/papra ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "papra" "papra-hq/papra"; then
    msg_info "Stopping Service"
    systemctl stop papra
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /opt/papra/apps/papra-server/.env /opt/papra_env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "papra" "papra-hq/papra" "tarball"

    msg_info "Building Application"
    cd /opt/papra
    cp /opt/papra_env.bak /opt/papra/apps/papra-server/.env
    $STD pnpm install --frozen-lockfile
    $STD pnpm --filter "@papra/app-client..." run build
    $STD pnpm --filter "@papra/app-server..." run build
    ln -sf /opt/papra/apps/papra-client/dist /opt/papra/apps/papra-server/public
    rm -f /opt/papra_env.bak
    msg_ok "Built Application"

    msg_info "Starting Service"
    systemctl start papra
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1221${CL}"
