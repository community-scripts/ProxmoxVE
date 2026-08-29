#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Omar Minaya | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/C4illin/ConvertX

APP="ConvertX"
var_tags="${var_tags:-converter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/convertx ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "ConvertX" "C4illin/ConvertX"; then
    msg_info "Stopping Service"
    systemctl stop convertx
    msg_info "Stopped Service"

    ensure_dependencies libreoffice-writer dasel graphicsmagick libemail-outlook-message-perl libheif-examples libjxl-tools resvg

    if ! command -v markitdown &>/dev/null; then
      setup_uv
      msg_info "Installing markitdown"
      export UV_TOOL_BIN_DIR=/usr/local/bin
      $STD uv tool install "markitdown[all]"
      msg_ok "Installed markitdown"
    fi

    if ! command -v vtracer &>/dev/null; then
      fetch_and_deploy_gh_release "vtracer" "visioncortex/vtracer" "prebuild" "0.6.4" "/usr/local/bin" "vtracer-$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl.tar.gz"
    fi

    create_backup /opt/convertx/data

    fetch_and_deploy_gh_release "ConvertX" "C4illin/ConvertX" "tarball" "latest" "/opt/convertx"

    restore_backup

    msg_info "Updating ConvertX"
    cd /opt/convertx
    $STD bun install
    msg_ok "Updated ConvertX"

    msg_info "Starting Service"
    systemctl start convertx
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}
start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
