#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/windmill-labs/windmill

APP="Windmill"
var_tags="${var_tags:-automation;workflow;scripts}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # upstream ships the CE binary for amd64 only
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/windmill/windmill ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "windmill" "windmill-labs/windmill"; then
    msg_info "Stopping Windmill"
    systemctl stop windmill
    msg_ok "Stopped Windmill"

    setup_uv
    NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
    fetch_and_deploy_gh_release "windmill" "windmill-labs/windmill" "singlefile" "latest" "/opt/windmill" "windmill-amd64"
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "windmill-duckdb" "windmill-labs/windmill" "singlefile" "latest" "/opt/windmill" "windmill_duckdb_runner"

    msg_info "Starting Windmill"
    systemctl start windmill
    msg_ok "Started Windmill"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
