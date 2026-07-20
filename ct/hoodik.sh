#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hudikhq/hoodik

APP="Hoodik"
var_tags="${var_tags:-cloud;storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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

  if [[ ! -f /opt/hoodik/hoodik ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "hoodik" "hudikhq/hoodik"; then
    msg_info "Stopping Service"
    systemctl stop hoodik
    msg_ok "Stopped Service"

    create_backup /opt/hoodik/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hoodik" "hudikhq/hoodik" "prebuild" "latest" "/opt/hoodik" "*$(arch_resolve "x86_64" "arm64").tar.gz"

    restore_backup

    msg_info "Starting Service"
    systemctl start hoodik
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:5443/auth/register${CL}"
