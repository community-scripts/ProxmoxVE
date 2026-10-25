#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/EgalitarianMonkey/hometube

APP="HomeTube"
var_tags="${var_tags:-media;youtube;downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/hometube ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating yt-dlp"
  $STD yt-dlp -U
  msg_ok "Updated yt-dlp"

  fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"

  if check_for_gh_release "hometube" "EgalitarianMonkey/hometube"; then
    msg_info "Stopping HomeTube"
    systemctl stop hometube
    msg_ok "Stopped HomeTube"

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hometube" "EgalitarianMonkey/hometube" "tarball"

    msg_info "Updating HomeTube"
    cd /opt/hometube
    $STD uv sync --locked --no-dev --no-install-project --no-install-package pyarrow
    msg_ok "Updated HomeTube"

    msg_info "Starting HomeTube"
    systemctl start hometube
    msg_ok "Started HomeTube"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8501${CL}"
