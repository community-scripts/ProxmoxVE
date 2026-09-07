#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/RiDDiX/home-assistant-matter-hub

APP="Matter-Hub"
var_tags="${var_tags:-smarthome;matter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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

  if [[ ! -d /opt/matter-hub ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "matter-hub" "RiDDiX/home-assistant-matter-hub"; then
    msg_info "Stopping Service"
    systemctl stop matter-hub
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "matter-hub" "RiDDiX/home-assistant-matter-hub" "tarball"

    msg_info "Building Matter Hub"
    cd /opt/matter-hub
    MATTER_HUB_VERSION=$(cat ~/.matter-hub)
    $STD pnpm install --frozen-lockfile
    $STD pnpm run release:version "$MATTER_HUB_VERSION"
    APP_VERSION="$MATTER_HUB_VERSION" $STD pnpm build
    sed -i "s|^APP_VERSION=.*|APP_VERSION=${MATTER_HUB_VERSION}|" /opt/matter-hub.env
    msg_ok "Built Matter Hub"

    msg_info "Installing Matter Hub"
    rm -rf /opt/matter-hub_app/node_modules /opt/matter-hub_app/package-lock.json
    cd /opt/matter-hub_app
    $STD npm install --omit=dev --no-audit --no-fund
    msg_ok "Installed Matter Hub"

    msg_info "Starting Service"
    systemctl start matter-hub
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
echo -e "${GATEWAY}${BGN}http://${IP}:8482${CL}"
echo -e "${INFO}${YW}Set your Home Assistant URL and token in /opt/matter-hub.env first${CL}"
