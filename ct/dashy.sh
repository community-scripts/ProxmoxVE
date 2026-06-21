#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dashy.to/

APP="Dashy"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/dashy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack,yarn" setup_nodejs

  if check_for_gh_release "dashy" "Lissy93/dashy"; then
    msg_info "Stopping Service"
    systemctl stop dashy
    msg_ok "Stopped Service"

    create_backup /opt/dashy/user-data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dashy" "lissy93/dashy" "prebuild" "latest" "/opt/dashy" "dashy-*.tar.gz"

    msg_info "Updating Dashy"
    cd /opt/dashy
    $STD yarn install --ignore-engines --network-timeout 300000
    msg_ok "Updated Dashy"

    restore_backup

    msg_info "Starting Dashy"
    systemctl start dashy
    msg_ok "Started Dashy"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:4000${CL}"
