#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teableio/teable

APP="Teable"
var_tags="${var_tags:-database;no-code;spreadsheet}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-25}"
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

  if [[ ! -d /opt/teable ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "teable" "teableio/teable"; then
    msg_info "Stopping Service"
    systemctl stop teable
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /opt/teable/.env /opt/teable.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "teable" "teableio/teable" "tarball"

    msg_info "Restoring Configuration"
    mv /opt/teable.env.bak /opt/teable/.env
    msg_ok "Restored Configuration"

    msg_info "Rebuilding Teable"
    cd /opt/teable
    TEABLE_VERSION=$(cat ~/.teable)
    echo "NEXT_PUBLIC_BUILD_VERSION=\"${TEABLE_VERSION}\"" >>apps/nextjs-app/.env
    export HUSKY=0
    export NODE_OPTIONS="--max-old-space-size=8192"
    $STD pnpm install --frozen-lockfile
    $STD pnpm -F @teable/db-main-prisma prisma-generate --schema ./prisma/postgres/schema.prisma
    NODE_ENV=production NEXT_BUILD_ENV_TYPECHECK=false \
      $STD pnpm -r --filter '!playground' run build
    msg_ok "Rebuilt Teable"

    msg_info "Running Database Migrations"
    source /opt/teable/.env
    $STD pnpm -F @teable/db-main-prisma prisma-migrate deploy --schema ./prisma/postgres/schema.prisma
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start teable
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update available."
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
