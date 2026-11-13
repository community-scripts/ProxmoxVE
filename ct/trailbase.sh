#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/trailbaseio/trailbase

APP="TrailBase"
var_tags="${var_tags:-backend;database;api}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/trailbase ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "trailbase" "trailbaseio/trailbase"; then
    msg_info "Stopping TrailBase"
    systemctl stop trailbase
    msg_ok "Stopped TrailBase"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "trailbase" "trailbaseio/trailbase" "prebuild" "latest" "/opt/trailbase" "trailbase_v*_$(arch_resolve "x86_64" "aarch64")_linux.zip"

    msg_info "Starting TrailBase"
    systemctl start trailbase
    msg_ok "Started TrailBase"
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
echo -e "${GATEWAY}${BGN}http://${IP}:4000/_/admin/${CL}"
echo -e "${INFO}${YW}Admin login: /opt/trailbase_data/.env (inside the container)${CL}"
