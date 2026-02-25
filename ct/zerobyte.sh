#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nicotsx/zerobyte

APP="Zerobyte"
var_tags="${var_tags:-backup;encryption;restic}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/zerobyte ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "zerobyte" "nicotsx/zerobyte"; then
    msg_info "Stopping Service"
    systemctl stop zerobyte
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /opt/zerobyte/.env /opt/zerobyte.env.bak
    msg_ok "Backed up Configuration"
    
    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "zerobyte" "nicotsx/zerobyte" "tarball"

    msg_info "Building Zerobyte"
    export NODE_OPTIONS="--max-old-space-size=3072"
    cd /opt/zerobyte
    $STD bun install
    $STD node ./node_modules/vite/bin/vite.js build
    msg_ok "Built Zerobyte"

    msg_info "Restoring Configuration"
    cp /opt/zerobyte.env.bak /opt/zerobyte/.env
    rm -f /opt/zerobyte.env.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start zerobyte
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4096${CL}"
