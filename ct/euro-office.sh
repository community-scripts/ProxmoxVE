#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Euro-Office/DocumentServer

APP="Euro-Office"
var_tags="${var_tags:-office;documents;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /var/www/euro-office/documentserver ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "euro-office" "Euro-Office/DocumentServer"; then
    msg_info "Stopping Euro-Office"
    $STD documentserver-prepare4shutdown.sh
    systemctl stop ds-docservice ds-converter ds-metrics ds-example
    msg_ok "Stopped Euro-Office"

    fetch_and_deploy_gh_release "euro-office" "Euro-Office/DocumentServer" "binary" "latest" "" "euro-office-documentserver_*_$(arch_resolve).deb"

    msg_info "Starting Euro-Office"
    systemctl start ds-metrics ds-converter ds-docservice
    if systemctl is-enabled -q ds-example; then
      systemctl start ds-example
    fi
    systemctl reload nginx
    msg_ok "Started Euro-Office"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW}JWT secret: documentserver-jwt-status.sh (inside the container)${CL}"
