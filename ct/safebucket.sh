#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: renizmy
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/safebucket/safebucket

APP="Safebucket"
var_tags="${var_tags:-files;sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -f /opt/safebucket/safebucket ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "safebucket" "safebucket/safebucket"; then
    local ARCH
    ARCH=$(arch_resolve)

    msg_info "Stopping Service"
    systemctl stop safebucket
    msg_ok "Stopped Service"

    create_backup /opt/safebucket/config.yaml /opt/safebucket/data/
    fetch_and_deploy_gh_release "safebucket" "safebucket/safebucket" "singlefile" "latest" "/opt/safebucket" "safebucket-linux-${ARCH}"
    restore_backup

    msg_info "Configuring Safebucket"
    chown -R safebucket:safebucket /opt/safebucket
    msg_ok "Configured Safebucket"

    msg_info "Starting Service"
    systemctl start safebucket
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  cleanup_lxc
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
