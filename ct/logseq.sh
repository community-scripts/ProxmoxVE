#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://logseq.com/

APP="Logseq"
var_tags="${var_tags:-notes;knowledge-base}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/logseq ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "logseq" "logseq/logseq"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "logseq" "logseq/logseq" "tarball"

    msg_info "Building Logseq Web App (Patience)"
    cd /opt/logseq
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export NODE_OPTIONS="--max-old-space-size=4096"
    export JAVA_TOOL_OPTIONS="-Xmx4g"
    $STD corepack enable
    $STD pnpm install --config.network-timeout=240000
    $STD pnpm release
    msg_ok "Built Logseq Web App"

    msg_info "Reloading Webserver"
    systemctl reload nginx
    msg_ok "Reloaded Webserver"
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
