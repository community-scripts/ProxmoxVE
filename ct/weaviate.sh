#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/weaviate/weaviate

APP="Weaviate"
var_tags="${var_tags:-database;vector;ai}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_api_key="${var_api_key:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/weaviate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "weaviate" "weaviate/weaviate"; then
    msg_info "Stopping Weaviate"
    systemctl stop weaviate
    msg_ok "Stopped Weaviate"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "weaviate" "weaviate/weaviate" "prebuild" "latest" "/opt/weaviate" "weaviate-v*-linux-$(arch_resolve).tar.gz"

    msg_info "Starting Weaviate"
    systemctl start weaviate
    msg_ok "Started Weaviate"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}API key (user admin): /opt/weaviate_data/.env (inside the container)${CL}"
