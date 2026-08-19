#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.ntop.org/products/traffic-analysis/ntop/

APP="ntopng"
var_tags="${var_tags:-network;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -f /etc/ntopng/ntopng.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ntopng"
  $STD apt update
  $STD apt install -y ntopng
  msg_ok "Updated ntopng"

  msg_info "Restarting Service"
  systemctl restart ntopng
  msg_ok "Restarted Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW}Default login: admin / admin${CL}"
