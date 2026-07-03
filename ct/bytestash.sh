#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

APP="ByteStash"
var_tags="${var_tags:-code}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/bytestash ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "bytestash" "jordan-dalby/ByteStash"; then
    msg_info "Stopping Services"
    systemctl stop bytestash-backend bytestash-frontend
    msg_ok "Services Stopped"

    [[ -d /opt/bytestash/data ]] && create_backup /opt/bytestash/data
    [[ -d /opt/data ]] && create_backup /opt/data
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bytestash" "jordan-dalby/ByteStash" "tarball"
    restore_backup

    msg_info "Configuring ByteStash"
    cd /opt/bytestash/server
    $STD npm install
    cd /opt/bytestash/client
    $STD npm install
    msg_ok "Updated ByteStash"

    msg_info "Starting Services"
    systemctl start bytestash-backend bytestash-frontend
    msg_ok "Started Services"

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
