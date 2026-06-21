#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/twentyhq/twenty

APP="Twenty"
var_tags="${var_tags:-crm;business;contacts}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/twenty ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

  if check_for_gh_release "twenty" "twentyhq/twenty"; then
    msg_info "Stopping Services"
    systemctl stop twenty-worker twenty-server
    msg_ok "Stopped Services"

    create_backup /opt/twenty/.env \
                  /opt/twenty/packages/twenty-server/.local-storage
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "twenty" "twentyhq/twenty" "tarball"

    msg_info "Restoring Configuration"
    cp /opt/twenty.env.bak /opt/twenty/.env
    msg_ok "Restored Configuration"

    msg_info "Building Application"
    cd /opt/twenty
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

    $STD corepack prepare yarn@4.9.2 --activate
    export NODE_OPTIONS="--max-old-space-size=3072"
    $STD yarn install --immutable || $STD yarn install
    $STD npx nx run twenty-server:build
    $STD npx nx build twenty-front
    cp -r /opt/twenty/packages/twenty-front/build /opt/twenty/packages/twenty-server/dist/front
    unset NODE_OPTIONS
    msg_ok "Built Application"

    msg_info "Running Database Migrations"
    cd /opt/twenty/packages/twenty-server
    set -a && source /opt/twenty/.env && set +a
    $STD npx ts-node ./scripts/setup-db.ts
    $STD npx -y typeorm migration:run -d dist/database/typeorm/core/core.datasource
    msg_ok "Ran Database Migrations"

    restore_backup

    msg_info "Starting Services"
    systemctl start twenty-server twenty-worker
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
