#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Gimanh/taskview-community

APP="TaskView"
var_tags="${var_tags:-project-management;tasks;kanban}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/taskview ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "taskview" "Gimanh/taskview-community"; then
    msg_info "Stopping TaskView"
    systemctl stop taskview
    msg_ok "Stopped TaskView"

    NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "taskview" "Gimanh/taskview-community" "tarball"

    msg_info "Building TaskView"
    cd /opt/taskview
    $STD pnpm install --frozen-lockfile
    cd /opt/taskview/api
    $STD pnpm run build:docker
    $STD pnpm run build:migration
    cp -r src/migrations/taskview dist-migration/
    cd /opt/taskview/web
    $STD pnpm run build:packages
    $STD pnpm run build-only
    msg_ok "Built TaskView"

    msg_info "Migrating TaskView Database"
    cd /opt/taskview_data
    $STD node /opt/taskview/api/dist-migration/taskview-db-migration.js
    msg_ok "Migrated TaskView Database"

    msg_info "Starting TaskView"
    systemctl start taskview
    msg_ok "Started TaskView"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
