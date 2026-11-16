#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/get-convex/convex-backend

APP="Convex"
var_tags="${var_tags:-backend;database;realtime}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/convex ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "convex" "get-convex/convex-backend"; then
    msg_info "Stopping Convex"
    systemctl stop convex
    msg_ok "Stopped Convex"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "convex" "get-convex/convex-backend" "prebuild" "latest" "/opt/convex" "convex-local-backend-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "convex-dashboard" "get-convex/convex-backend" "prebuild" "$(cat ~/.convex)" "/opt/convex-dashboard" "dashboard.zip"

    msg_info "Starting Convex"
    systemctl start convex
    msg_ok "Started Convex"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access the dashboard using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:6791${CL}"
echo -e "${INFO}${YW}Deployment URL: http://${IP}:3210, admin key in /opt/convex_data/.env${CL}"
