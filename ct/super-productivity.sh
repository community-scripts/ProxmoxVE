#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://super-productivity.com/

APP="Super-Productivity"
var_tags="${var_tags:-productivity;todo}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/super-productivity ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "super-productivity" "super-productivity/super-productivity"; then
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "super-productivity" "super-productivity/super-productivity" "tarball"

    msg_info "Building Web App"
    cd /opt/super-productivity
    export HUSKY=0
    export UNSPLASH_KEY=DUMMY_UNSPLASH_KEY
    export UNSPLASH_CLIENT_ID=DUMMY_UNSPLASH_CLIENT_ID
    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD git config --global url."https://github.com/".insteadOf ssh://git@github.com/
    $STD npm ci
    $STD npm run buildFrontend:prodWeb
    msg_ok "Built Web App"

    msg_info "Deploying Web App"
    rm -rf /var/www/html/*
    cp -r /opt/super-productivity/dist/browser/. /var/www/html/
    systemctl reload nginx
    msg_ok "Deployed Web App"
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
