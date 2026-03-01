#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustmailer/bichon

APP="Bichon"
var_tags="${var_tags:-email;archive}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/bichon ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "bichon" "rustmailer/bichon"; then
    msg_info "Stopping service"
    systemctl stop bichon
    msg_ok "Stopped service"

    cp /opt/bichon/bichon.env /tmp/bichon.env.backup
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bichon" "rustmailer/bichon" "prebuild" "latest" "/opt/bichon" "bichon-*-x86_64-unknown-linux-gnu.tar.gz"
    cp /tmp/bichon.env.backup /opt/bichon/bichon.env

    msg_info "Starting service"
    systemctl start bichon
    msg_ok "Service started"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:15630${CL}"
