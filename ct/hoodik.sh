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

    msg_info "Backing up Configuration"
    cp /opt/hoodik/.env /opt/hoodik.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hoodik" "hudikhq/hoodik" "prebuild" "latest" "/opt/hoodik" "*x86_64.tar.gz"

    msg_info "Restoring Configuration"
    cp /opt/hoodik.env.bak /opt/hoodik/.env
    rm -f /opt/hoodik.env.bak
    msg_ok "Restored Configuration"

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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5443/auth/register${CL}"
