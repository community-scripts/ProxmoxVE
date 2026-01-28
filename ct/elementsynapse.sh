#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/element-hq/synapse

APP="Element Synapse"
var_tags="${var_tags:-server}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /etc/matrix-synapse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

  msg_info "Updating LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated LXC"

  if check_for_gh_release "synapse-admin" "etkecc/synapse-admin"; then
    msg_info "Stopping Service"
    systemctl stop synapse-admin
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "synapse-admin" "etkecc/synapse-admin" "tarball" "latest" "/opt/synapse-admin"

    msg_info "Building Synapse-Admin"
    cd /opt/synapse-admin
    $STD yarn global add serve
    $STD yarn install --ignore-engines
    $STD yarn build
    mv ./dist ../ && rm -rf * && mv ../dist ./
    msg_ok "Built Synapse-Admin"

    msg_info "Starting Service"
    systemctl start synapse-admin
    msg_ok "Started Service"
    msg_ok "Updated Synapse-Admin to ${CHECK_UPDATE_RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8008${CL}"
