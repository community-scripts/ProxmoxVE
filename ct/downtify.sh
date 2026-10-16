#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/henriquesebastiao/downtify

APP="Downtify"
var_tags="${var_tags:-music;downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/downtify ]]; then
    msg_error "No Downtify Installation Found!"
    exit
  fi

  if check_for_gh_release "downtify" "henriquesebastiao/downtify"; then
    msg_info "Stopping Downtify"
    systemctl stop downtify
    msg_ok "Stopped Downtify"

    PYTHON_VERSION="3.14" setup_uv
    NODE_VERSION="26" setup_nodejs
    fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "downtify" "henriquesebastiao/downtify" "tarball"

    msg_info "Building Downtify"
    cd /opt/downtify/frontend
    $STD npm ci
    $STD npm run build
    rm -rf /opt/downtify/frontend/node_modules
    cd /opt/downtify
    $STD uv sync --frozen --no-dev --python 3.14
    msg_ok "Built Downtify"

    msg_info "Starting Downtify"
    systemctl start downtify
    msg_ok "Started Downtify"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW}Sign in as admin / downtify and change the password right away${CL}"
