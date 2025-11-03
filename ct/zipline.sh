#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zipline.diced.sh/

APP="Zipline"
var_tags="${var_tags:-file;sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/zipline ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs

  if check_for_gh_release "zipline" "diced/zipline"; then
    msg_info "Stopping Service"
    systemctl stop zipline
    msg_ok "Service Stopped"

    mkdir -p /opt/zipline-uploads
    if [ -d /opt/zipline/uploads ] && [ "$(ls -A /opt/zipline/uploads)" ]; then
      cp -R /opt/zipline/uploads/* /opt/zipline-uploads/
    fi
    cp /opt/zipline/.env /opt/
    rm -R /opt/zipline
    fetch_and_deploy_gh_release "zipline" "diced/zipline" "tarball"

    msg_info "Updating ${APP}"
    cd /opt/zipline || exit
    mv /opt/.env /opt/zipline/.env
    $STD pnpm install
    $STD pnpm build
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start zipline
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
