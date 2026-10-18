#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DuarteSantos8/openGym

APP="openGym"
var_tags="${var_tags:-health;fitness}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/opengym ]]; then
    msg_error "No openGym Installation Found!"
    exit
  fi

  if check_for_gh_release "opengym" "DuarteSantos8/openGym" "" "" "v"; then
    msg_info "Stopping openGym"
    systemctl stop nginx opengym
    msg_ok "Stopped openGym"

    NODE_VERSION="22" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "opengym" "DuarteSantos8/openGym" "tarball" "latest" "/opt/opengym" "" "v"

    msg_info "Building openGym"
    cd /opt/opengym/api
    $STD npm ci --omit=dev --omit=optional
    cd /opt/opengym/frontend
    $STD npm ci --ignore-scripts
    $STD npm run build
    rm -rf /opt/opengym/frontend/node_modules ~/.npm
    msg_ok "Built openGym"

    msg_info "Starting openGym"
    systemctl start opengym nginx
    msg_ok "Started openGym"
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
echo -e "${INFO}${YW}Sign-in is by password over plain HTTP. Create your profile right away: the first one becomes the admin.${CL}"
echo -e "${INFO}${YW}For passkeys, serve it over HTTPS on a hostname through a reverse proxy, then set RP_ID and ORIGIN in /opt/opengym_data/.env and run systemctl restart opengym. Changing RP_ID later invalidates existing passkeys.${CL}"
