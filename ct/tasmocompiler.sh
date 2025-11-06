#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

APP="TasmoCompiler"
var_tags="${var_tags:-compiler}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/tasmocompiler ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop tasmocompiler
    msg_ok "Stopped Service"

    msg_info "Updating TasmoCompiler"
    cd /opt
    rm -rf /opt/tasmocompiler
    RELEASE=$(curl -fsSL https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    curl -fsSL "https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz" -o $(basename "https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz")
    tar xzf v${RELEASE}.tar.gz
    mv tasmocompiler-${RELEASE}/ /opt/tasmocompiler/
    cd /opt/tasmocompiler
    $STD yarn install
    export NODE_OPTIONS=--openssl-legacy-provider
    $STD npm i
    $STD yarn build
    msg_ok "Updated TasmoCompiler"

    msg_info "Starting Service"
    systemctl start tasmocompiler
    msg_ok "Started Service"

    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_info "Cleaning up"
    rm -r "/opt/v${RELEASE}.tar.gz"
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
