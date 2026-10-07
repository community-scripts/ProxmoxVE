#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pgsty/silo

APP="Silo"
var_tags="${var_tags:-storage;s3}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -f /usr/bin/silo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "silo" "pgsty/silo"; then
    msg_info "Stopping Silo"
    systemctl stop silo
    msg_ok "Stopped Silo"

    DPKG_FORCE_CONFOLD=1 fetch_and_deploy_gh_release "silo" "pgsty/silo" "binary"

    msg_info "Starting Silo"
    systemctl start silo
    msg_ok "Started Silo"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Console:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9001${CL}"
echo -e "${INFO}${YW}S3 API on port 9000 - root credentials are in /etc/default/silo${CL}"
