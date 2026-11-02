#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: uchouT (uchouT)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/OpenListTeam/OpenList/

APP="OpenList"
var_tags="${var_tags:-files;storage}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine 3.24 (smaller)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-6}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

update_deb_based() {
  if [[ ! -f /opt/openlist/openlist ]]; then
    msg_error "No OpenList Installation Found!"
    exit 1
  fi

  if check_for_gh_release "openlist" "OpenListTeam/OpenList"; then
    msg_info "Stopping OpenList"
    systemctl stop openlist
    msg_ok "Stopped OpenList"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "openlist" "OpenListTeam/OpenList" "prebuild" "latest" "/opt/openlist" "openlist-linux-musl-$(arch_resolve "amd64" "arm64").tar.gz"

    msg_info "Starting OpenList"
    systemctl start openlist
    msg_ok "Started OpenList"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -f /opt/openlist/openlist ]]; then
    msg_error "No OpenList Installation Found!"
    exit 1
  fi

  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  if check_for_gh_release "openlist" "OpenListTeam/OpenList"; then
    msg_info "Stopping OpenList"
    $STD rc-service openlist stop
    msg_ok "Stopped OpenList"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "openlist" "OpenListTeam/OpenList" "prebuild" "latest" "/opt/openlist" "openlist-linux-musl-$(arch_resolve "amd64" "arm64").tar.gz"

    msg_info "Starting OpenList"
    $STD rc-service openlist start
    msg_ok "Started OpenList"
    msg_ok "Updated successfully!"
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5244${CL}"
echo -e "${INFO}${YW}Credentials saved in:${CL}"
echo -e "${TAB}/root/openlist.creds"
