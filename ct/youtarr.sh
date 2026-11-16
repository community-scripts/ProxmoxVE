#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DialmasterOrg/Youtarr

APP="Youtarr"
var_tags="${var_tags:-media;youtube;downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/youtarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating yt-dlp"
  $STD yt-dlp -U
  msg_ok "Updated yt-dlp"

  if check_for_gh_release "youtarr" "DialmasterOrg/Youtarr"; then
    msg_info "Stopping Youtarr"
    systemctl stop youtarr
    msg_ok "Stopped Youtarr"

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "youtarr" "DialmasterOrg/Youtarr" "tarball"

    msg_info "Building Youtarr"
    cd /opt/youtarr/client
    $STD npm ci --ignore-scripts
    $STD npm run build
    rm -rf /opt/youtarr/client/node_modules
    cd /opt/youtarr
    $STD npm ci --omit=dev --ignore-scripts
    mv /opt/youtarr/config/config.example.json /opt/youtarr/server/
    rm -rf /opt/youtarr/config
    ln -sfn /opt/youtarr_data/config /opt/youtarr/config
    msg_ok "Built Youtarr"

    msg_info "Starting Youtarr"
    systemctl start youtarr
    msg_ok "Started Youtarr"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3011${CL}"
echo -e "${INFO}${YW}First login asks for the setup token in /opt/youtarr_data/config/setup-token${CL}"
