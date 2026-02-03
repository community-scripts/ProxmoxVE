#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://heimdall.site/

APP="Heimdall-Dashboard"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=7990
WEB_UI_PROTOCOL="http"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/Heimdall ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Heimdall" "linuxserver/Heimdall"; then
    msg_info "Stopping Service"
    systemctl stop heimdall
    sleep 1
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -R /opt/Heimdall/database database-backup
    cp -R /opt/Heimdall/public public-backup
    sleep 1
    msg_ok "Backed up Data"

    setup_composer
    fetch_and_deploy_gh_release "Heimdall" "linuxserver/Heimdall" "tarball"

    msg_info "Updating Heimdall-Dashboard"
    cd /opt/Heimdall
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer dump-autoload
    msg_ok "Updated Heimdall-Dashboard"

    msg_info "Restoring Data"
    cd ~
    cp -R database-backup/* /opt/Heimdall/database
    cp -R public-backup/* /opt/Heimdall/public
    sleep 1
    msg_ok "Restored Data"

    msg_info "Cleaning Up"
    rm -rf {public-backup,database-backup}
    sleep 1
    msg_ok "Cleaned Up"

    msg_info "Starting Service"
    systemctl start heimdall.service
    sleep 2
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7990${CL}"
