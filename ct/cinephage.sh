#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MoldyTaint/Cinephage

APP="Cinephage"
var_tags="${var_tags:-arr;media;torrent;usenet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/cinephage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "cinephage" "MoldyTaint/Cinephage"; then
    msg_info "Stopping Cinephage"
    systemctl stop cinephage
    msg_ok "Stopped Cinephage"

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cinephage" "MoldyTaint/Cinephage" "tarball"

    msg_info "Building Cinephage"
    cd /opt/cinephage
    $STD npm ci
    $STD npm run build
    $STD npm prune --omit=dev
    sed -i "s/^APP_VERSION=.*/APP_VERSION=$(cat ~/.cinephage)/" /opt/cinephage_data/.env
    msg_ok "Built Cinephage"

    msg_info "Updating Camoufox"
    $STD /opt/cinephage/node_modules/.bin/camoufox-js fetch
    msg_ok "Updated Camoufox"

    msg_info "Starting Cinephage"
    systemctl start cinephage
    msg_ok "Started Cinephage"
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
