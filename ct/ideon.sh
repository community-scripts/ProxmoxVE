#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/3xpyth0n/ideon

APP="Ideon"
var_tags="${var_tags:-notes;canvas;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/ideon ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  $STD sudo -u postgres psql -c "ALTER ROLE ideon BYPASSRLS;"

  if check_for_gh_release "ideon" "3xpyth0n/ideon"; then
    NODE_VERSION="26" setup_nodejs
    
    msg_info "Stopping Ideon"
    systemctl stop ideon
    msg_ok "Stopped Ideon"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ideon" "3xpyth0n/ideon" "tarball"

    msg_info "Building Ideon"
    cd /opt/ideon
    $STD npm ci
    NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production IS_NEXT_BUILD=1 $STD npm run build
    $STD npm prune --omit=dev
    rm -rf /opt/ideon/.next/cache ~/.npm
    ln -s /opt/ideon_data/storage /opt/ideon/storage
    msg_ok "Built Ideon"

    msg_info "Starting Ideon"
    systemctl start ideon
    msg_ok "Started Ideon"
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
