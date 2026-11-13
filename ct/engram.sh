#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Gentleman-Programming/engram

APP="Engram"
var_tags="${var_tags:-ai;mcp;memory}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_cloud_token="${var_cloud_token:-}"
export var_admin_token="${var_admin_token:-}"
export var_allowed_projects="${var_allowed_projects:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/engram/engram ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "engram" "Gentleman-Programming/engram"; then
    msg_info "Stopping Engram"
    systemctl stop engram
    msg_ok "Stopped Engram"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "engram" "Gentleman-Programming/engram" "prebuild" "latest" "/opt/engram" "engram_*_linux_$(arch_resolve).tar.gz"

    msg_info "Starting Engram"
    systemctl start engram
    msg_ok "Started Engram"
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
echo -e "${GATEWAY}${BGN}https://${IP}/dashboard/${CL}"
echo -e "${INFO}${YW}Sync and admin tokens: /opt/engram_data/.env (inside the container)${CL}"
