#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

APP="Wireguard"
var_tags="${var_tags:-network;vpn}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_tun="${var_tun:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /etc/wireguard ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! dpkg -s git >/dev/null 2>&1; then
    msg_info "Installing git"
    $STD apt update
    $STD apt install -y git
    msg_ok "Installed git"
  fi
  apt update
  apt -y upgrade
  if [[ -d /etc/wgdashboard ]]; then
    sleep 2
    cd /etc/wgdashboard/src || exit
    ./wgd.sh update
    ./wgd.sh start
  fi
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access WGDashboard (if installed) using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:10086${CL}"
