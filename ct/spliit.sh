#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: phof
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/spliit-app/spliit

APP="Spliit"
var_tags="${var_tags:-finance;expense-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/spliit ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "spliit" "spliit-app/spliit"; then
    msg_info "Stopping Service"
    systemctl stop spliit
    msg_ok "Stopped Service"

    create_backup /opt/spliit/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "spliit" "spliit-app/spliit" "tarball"

    restore_backup
    NODE_VERSION="24" setup_nodejs

    msg_info "Building Application"
    cd /opt/spliit
    $STD npm ci --ignore-scripts
    $STD npx prisma generate
    $STD npm run build
    msg_ok "Built Application"

    msg_info "Running Database Migrations"
    cd /opt/spliit
    $STD npx prisma migrate deploy
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start spliit
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
