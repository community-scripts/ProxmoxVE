#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ridafkih/keeper.sh

APP="Keeper"
var_tags="${var_tags:-calendar;sync}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/keeper ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "keeper" "ridafkih/keeper.sh"; then
    msg_info "Stopping Keeper"
    systemctl stop keeper-web keeper-worker keeper-cron keeper-api
    msg_ok "Stopped Keeper"

    msg_info "Updating Bun"
    $STD bun upgrade
    msg_ok "Updated Bun"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "keeper" "ridafkih/keeper.sh" "tarball"

    msg_info "Building Keeper"
    cd /opt/keeper
    $STD bun install --frozen-lockfile
    $STD bun run --cwd services/api build
    $STD bun run --cwd services/cron build
    $STD bun run --cwd services/worker build
    $STD bun run --cwd applications/web build
    msg_ok "Built Keeper"

    msg_info "Migrating Keeper Database"
    $STD bun --env-file=/opt/keeper_data/.env packages/database/scripts/migrate.ts
    msg_ok "Migrated Keeper Database"

    msg_info "Starting Keeper"
    systemctl start keeper-api keeper-cron keeper-worker keeper-web
    msg_ok "Started Keeper"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
