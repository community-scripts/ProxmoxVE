#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/blinkospace/blinko

APP="Blinko"
var_tags="${var_tags:-notes;ai;knowledge}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
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

  if [[ ! -d /opt/blinko ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "blinko" "blinkospace/blinko"; then
    msg_info "Stopping Blinko"
    systemctl stop blinko
    msg_ok "Stopped Blinko"

    NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "blinko" "blinkospace/blinko" "tarball"

    msg_info "Building Blinko"
    cd /opt/blinko
    $STD bun install
    $STD bunx prisma generate
    $STD bun run build:web
    $STD bun run build:seed
    mv dist/public server/public
    cp -r server/lute.min.js server/vditor dist/
    ln -s /opt/blinko_data/storage /opt/blinko/.blinko
    msg_ok "Built Blinko"

    msg_info "Starting Blinko"
    systemctl start blinko
    msg_ok "Started Blinko"
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
echo -e "${GATEWAY}${BGN}http://${IP}:1111${CL}"
