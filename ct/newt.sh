#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Arubinu
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fosrl/newt

APP="Newt"
var_tags="${var_tags:-network;tunnel}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
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

  if [[ ! -f /etc/newt/newt.env ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "newt" "fosrl/newt"; then
    msg_info "Stopping Service"
    systemctl stop newt
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "newt" "fosrl/newt" "singlefile" "latest" "/opt/newt" "newt_linux_$(arch_resolve)"
    ln -sf /opt/newt/newt /usr/local/bin/newt

    msg_info "Starting Service"
    systemctl start newt
    msg_ok "Started Service"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${INFO}${YW} Check the site status in your Pangolin dashboard.${CL}"
