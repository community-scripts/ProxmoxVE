#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: miviro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/heiher/hev-socks5-server

APP="hev-socks5-server"
var_tags="${var_tags:-proxy;socks5}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -f /opt/${APP} ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  
  if check_for_gh_release "hev-socks5-server" "heiher/hev-socks5-server"; then
    msg_info "Stopping Service"
    systemctl stop hev-socks5-server
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "hev-socks5-server" "heiher/hev-socks5-server" "singlefile" "latest" "/opt" "hev-socks5-server-linux-x86_64"

    msg_info "Starting Service"
    systemctl start hev-socks5-server
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
echo -e "${INFO}${YW} Access it with a SOCKS5 client using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:1080${CL}"
echo -e "${INFO}${YW} and the credentials stored at /root/hev.creds${CL}"
