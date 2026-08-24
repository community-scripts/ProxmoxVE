#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/johanohly/AirTrail

APP="AirTrail"
var_tags="${var_tags:-flights;tracking}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  if [[ ! -d /opt/airtrail ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "airtrail" "johanohly/AirTrail"; then
    msg_info "Stopping Service"
    systemctl stop airtrail
    msg_ok "Stopped Service"

    create_backup /opt/airtrail/.env /opt/airtrail/uploads

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "airtrail" "johanohly/AirTrail" "tarball" "latest" "/opt/airtrail"

    restore_backup

    msg_info "Rebuilding AirTrail (Patience)"
    cd /opt/airtrail
    $STD bun install --frozen-lockfile
    export NODE_ENV=production
    $STD bun run build
    $STD bun install --frozen-lockfile --production
    $STD bun run db:migrate-deploy
    msg_ok "Rebuilt AirTrail"

    msg_info "Starting Service"
    systemctl start airtrail
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
