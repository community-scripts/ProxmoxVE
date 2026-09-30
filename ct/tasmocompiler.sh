#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

APP="TasmoCompiler"
var_tags="${var_tags:-compiler}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/tasmocompiler ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -f /opt/${APP}_version.txt ]]; then
    mv /opt/"${APP}_version.txt" ~/.tasmocompiler
  fi

  if check_for_gh_release "tasmocompiler" "benzino77/tasmocompiler"; then
    msg_info "Stopping Service"
    systemctl stop tasmocompiler
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tasmocompiler" "benzino77/tasmocompiler" "tarball"

    msg_info "Updating TasmoCompiler"
    cd /opt/tasmocompiler
    $STD yarn install
    export NODE_OPTIONS=--openssl-legacy-provider
    $STD npm i
    $STD yarn build
    msg_ok "Updated TasmoCompiler"

    msg_info "Starting Service"
    systemctl start tasmocompiler
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
