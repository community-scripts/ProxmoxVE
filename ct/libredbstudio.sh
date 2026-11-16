#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yusuf Gundogdu (yusuf-gundogdu)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://libredb.org

APP="LibreDB Studio"
var_tags="${var_tags:-database;sql}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -f /usr/bin/libredb-studio ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "libredb-studio" "libredb/libredb-studio"; then
    msg_info "Stopping Service"
    systemctl stop libredb-studio
    msg_ok "Stopped Service"

    create_backup /etc/libredb-studio/env

    DPKG_FORCE_CONFOLD=1 fetch_and_deploy_gh_release "libredb-studio" "libredb/libredb-studio" "binary" "latest" "" "libredb-studio_*_$(arch_resolve).deb"

    restore_backup

    msg_info "Starting Service"
    systemctl start libredb-studio
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW}Admin credentials: /etc/libredb-studio/env inside the container${CL}"
