#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AnalogJ/scrutiny

APP="Scrutiny"
var_tags="${var_tags:-monitoring;smart;disk}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /opt/scrutiny/scrutiny ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "scrutiny" "AnalogJ/scrutiny"; then
    msg_info "Stopping Scrutiny"
    systemctl stop scrutiny
    msg_ok "Stopped Scrutiny"

    fetch_and_deploy_gh_release "scrutiny" "AnalogJ/scrutiny" "singlefile" "latest" "/opt/scrutiny" "scrutiny-web-linux-$(arch_resolve "amd64" "arm64")"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "scrutiny-web" "AnalogJ/scrutiny" "prebuild" "latest" "/opt/scrutiny/web" "scrutiny-web-frontend.tar.gz"

    msg_info "Starting Scrutiny"
    systemctl start scrutiny
    msg_ok "Started Scrutiny"
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
