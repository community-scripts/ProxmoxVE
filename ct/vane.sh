#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ItzCrazyKns/Vane

APP="Vane"
var_tags="${var_tags:-ai;search}"
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

  if [[ ! -d /opt/vane ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "vane" "ItzCrazyKns/Vane"; then
    msg_info "Stopping Vane"
    systemctl stop vane
    msg_ok "Stopped Vane"

    NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "vane" "ItzCrazyKns/Vane" "tarball"

    msg_info "Building Vane"
    cd /opt/vane
    $STD yarn install --frozen-lockfile --network-timeout 600000
    $STD yarn build
    $STD yarn cache clean
    rm -rf .next/cache
    cp -r public .next/standalone/
    cp -r .next/static .next/standalone/.next/
    cp -r drizzle .next/standalone/
    ln -s /opt/vane_data .next/standalone/data
    $STD npx playwright install --with-deps --only-shell chromium
    msg_ok "Built Vane"

    msg_info "Starting Vane"
    systemctl start vane
    msg_ok "Started Vane"
    msg_ok "Updated Vane successfully!"
  fi

  if check_for_gh_branch "searxng" "searxng/searxng" "master"; then
    msg_info "Stopping SearXNG"
    systemctl stop searxng
    msg_ok "Stopped SearXNG"

    PYTHON_VERSION="3.13" setup_uv
    fetch_and_deploy_gh_branch "searxng" "searxng/searxng" "master"

    msg_info "Updating SearXNG"
    cd /opt/searxng
    $STD uv pip install -p /opt/searxng/.venv/bin/python -r requirements.txt -r requirements-server.txt
    msg_ok "Updated SearXNG"

    msg_info "Starting SearXNG"
    systemctl start searxng
    msg_ok "Started SearXNG"
    msg_ok "Updated SearXNG successfully!"
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
