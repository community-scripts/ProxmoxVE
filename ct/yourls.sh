#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://yourls.org/

APP="YOURLS"
var_tags="${var_tags:-url-shortener;php}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /opt/yourls/yourls-loader.php ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "yourls" "YOURLS/YOURLS"; then
    msg_info "Stopping Service"
    systemctl stop nginx
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp -r /opt/yourls/user /opt/yourls_user.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "yourls" "YOURLS/YOURLS" "tarball"
    chown -R www-data:www-data /opt/yourls

    msg_info "Restoring Configuration"
    cp -r /opt/yourls_user.bak/. /opt/yourls/user/
    rm -rf /opt/yourls_user.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start nginx
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
echo -e "${INFO}${YW} First, complete the database setup at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/admin/install.php${CL}"
echo -e "${INFO}${YW} Admin credentials are in the install log:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}grep -A2 'admin' /opt/yourls/user/config.php${CL}"
