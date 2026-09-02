#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://unpackerr.zip/

APP="Unpackerr"
var_tags="${var_tags:-downloads;arr;automation;extraction}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -f /etc/unpackerr/unpackerr.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "unpackerr" "Unpackerr/unpackerr"; then
    msg_info "Stopping Service"
    systemctl stop unpackerr
    msg_ok "Stopped Service"

    create_backup /etc/unpackerr/unpackerr.conf

    DPKG_FORCE_CONFOLD=1 fetch_and_deploy_gh_release "unpackerr" "Unpackerr/unpackerr" "binary" "latest" "/opt/unpackerr" "unpackerr_*_$(arch_resolve).deb"

    restore_backup

    msg_info "Starting Service"
    systemctl start unpackerr
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
echo -e "${INFO}${YW}Configure integrations in:${CL}"
echo -e "${GATEWAY}${BGN}/etc/unpackerr/unpackerr.conf${CL}"
