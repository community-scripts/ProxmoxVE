#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mathias Wagner (gnmyt)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nexterm.dev/

APP="Nexterm"
var_tags="${var_tags:-server-management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -f /opt/nexterm/server/nexterm-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "nexterm-engine" "gnmyt/Nexterm"; then
    msg_info "Stopping nexterm-engine"
    systemctl stop nexterm-engine
    msg_ok "Stopped nexterm-engine"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nexterm-engine" "gnmyt/Nexterm" "prebuild" "latest" "/opt/nexterm/engine" "nexterm-engine-linux-${NX_ARCH}.tar.gz"

    msg_info "Starting nexterm-engine"
    systemctl start nexterm-engine
    msg_ok "Started nexterm-engine"
  fi

  if check_for_gh_release "nexterm-server" "gnmyt/Nexterm"; then
    msg_info "Stopping nexterm-server"
    systemctl stop nexterm-server
    msg_ok "Stopped nexterm-server"

    fetch_and_deploy_gh_release "nexterm-server" "gnmyt/Nexterm" "singlefile" "latest" "/opt/nexterm/server" "nexterm-server-linux-${NX_ARCH}"

    msg_info "Starting nexterm-server"
    systemctl start nexterm-server
    msg_ok "Started nexterm-server"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:6989${CL}"
