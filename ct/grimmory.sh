#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grimmory-tools/grimmory

APP="Grimmory"
var_tags="${var_tags:-books;ebooks;library}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # release jar bundles x64-only PDFium natives
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/grimmory/grimmory.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kepubify" "pgaskin/kepubify"; then
    fetch_and_deploy_gh_release "kepubify" "pgaskin/kepubify" "singlefile" "latest" "/usr/local/bin" "kepubify-linux-64bit"
  fi

  if check_for_gh_release "grimmory" "grimmory-tools/grimmory"; then
    msg_info "Stopping Grimmory"
    systemctl stop grimmory
    msg_ok "Stopped Grimmory"

    JAVA_VERSION="25" setup_java
    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "grimmory" "grimmory-tools/grimmory" "singlefile" "latest" "/opt/grimmory" "grimmory.jar"

    msg_info "Starting Grimmory"
    systemctl start grimmory
    msg_ok "Started Grimmory"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6060${CL}"
