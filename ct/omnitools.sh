#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Majiiin
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/iib0011/omni-tools

APP="OmniTools"
var_tags="${var_tags:-utilities;tools;converter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/omnitools ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "omnitools" "iib0011/omni-tools"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "omnitools" "iib0011/omni-tools" "tarball"

    msg_info "Building OmniTools"
    cd /opt/omnitools
    export HUSKY=0
    $STD npm ci
    $STD npm run build
    msg_ok "Built OmniTools"

    msg_info "Publishing Web Assets"
    rm -rf /usr/share/nginx/html
    mkdir -p /usr/share/nginx/html
    cp -a /opt/omnitools/dist/. /usr/share/nginx/html/
    rm -rf /opt/omnitools/node_modules
    systemctl reload nginx
    msg_ok "Published Web Assets"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
