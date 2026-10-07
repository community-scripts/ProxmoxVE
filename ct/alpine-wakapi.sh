#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wakapi.dev/ | https://github.com/muety/wakapi

APP="Alpine-Wakapi"
var_tags="${var_tags:-code;time-tracking}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.24}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -d /opt/wakapi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wakapi" "muety/wakapi"; then
    msg_info "Stopping Wakapi Service"
    $STD rc-service wakapi stop
    msg_ok "Stopped Wakapi Service"

    msg_info "Updating Wakapi LXC"
    $STD apk -U upgrade
    msg_ok "Updated Wakapi LXC"

    create_backup /opt/wakapi/config.yml /opt/wakapi/wakapi_db.db
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wakapi" "muety/wakapi" "prebuild" "latest" "/opt/wakapi" "wakapi_linux_$(arch_resolve).zip"
    restore_backup

    msg_info "Starting Service"
    $STD rc-service wakapi start
    msg_ok "Started Service"
    msg_ok "Updated successfully"
  fi
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
