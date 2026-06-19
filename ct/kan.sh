#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kanbn/kan

APP="Kan"
var_tags="${var_tags:-project-management;kanban}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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

  if [[ ! -d /opt/kan ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_tag "kan" "kanbn/kan"; then
    msg_info "Stopping Service"
    systemctl stop kan
    msg_ok "Stopped Service"

    create_backup /opt/kan/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "kan" "kanbn/kan" "latest"
    restore_backup

    msg_info "Building Application"
    cd /opt/kan
    set -a && source /opt/kan/.env && set +a
    export NEXT_PUBLIC_USE_STANDALONE_OUTPUT=true
    $STD pnpm install --ignore-scripts --prod=false
    export CI=true
    find /opt/kan/packages /opt/kan/apps -name 'tsconfig.json' -exec sed -i 's|"@kan/tsconfig/|"../../tooling/typescript/|g' {} +
    $STD pnpm build --filter=@kan/web
    unset NEXT_PUBLIC_USE_STANDALONE_OUTPUT CI
    msg_ok "Built Application"

    msg_info "Setting up Standalone"
    mkdir -p /opt/kan/apps/web/.next/standalone/apps/web/.next/static
    cp -r /opt/kan/apps/web/.next/static/* /opt/kan/apps/web/.next/standalone/apps/web/.next/static/
    cp -r /opt/kan/apps/web/public /opt/kan/apps/web/.next/standalone/apps/web/public
    msg_ok "Set up Standalone"

    msg_info "Running Database Migrations"
    cd /opt/kan/packages/db
    $STD pnpm exec drizzle-kit migrate
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start kan
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
