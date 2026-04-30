#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CanbiZ (MickLesk)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://neko.m1k1o.net/

APP="Neko"
var_tags="${var_tags:-virtual-browser;webrtc;streaming}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
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

  if [[ ! -d /opt/neko ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "neko" "m1k1o/neko"; then
    msg_info "Stopping Service"
    systemctl stop neko
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /etc/neko/neko.yaml /opt/neko.yaml.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "neko" "m1k1o/neko" "tarball"

    msg_info "Building Client"
    cd /opt/neko/client
    $STD npm install
    $STD npm run build
    cp -r /opt/neko/client/dist/* /var/www/
    msg_ok "Built Client"

    msg_info "Building Server"
    cd /opt/neko/server
    $STD ./build
    cp /opt/neko/server/bin/neko /usr/bin/neko
    cp -r /opt/neko/server/bin/plugins/* /etc/neko/plugins/ 2>/dev/null || true
    msg_ok "Built Server"

    msg_info "Restoring Data"
    cp /opt/neko.yaml.bak /etc/neko/neko.yaml
    rm -f /opt/neko.yaml.bak
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start neko
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
