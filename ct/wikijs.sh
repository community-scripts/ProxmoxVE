#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

APP="Wikijs"
var_tags="${var_tags:-wiki}"
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
  if [[ ! -d /opt/wikijs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn,node-gyp" setup_nodejs

  if check_for_gh_release "wikijs" "requarks/wiki"; then
    msg_info "Verifying whether ${APP}' new release is v3.x+ and current install uses SQLite."
    SQLITE_INSTALL=$([ -f /opt/wikijs/db.sqlite ] && echo "true" || echo "false")
    if [[ "${SQLITE_INSTALL}" == "true" && "${CHECK_UPDATE_RELEASE}" =~ ^3.* ]]; then
      echo "SQLite is not supported in v3.x+, currently there is no update path availble."
      exit
    fi
    msg_ok "There is an update path available for ${APP}"

    msg_info "Stopping Service"
    systemctl stop wikijs
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    mkdir /opt/wikijs-backup
    $SQLITE_INSTALL && cp /opt/wikijs/db.sqlite /opt/wikijs-backup
    cp -R /opt/wikijs/{config.yml,/data} /opt/wikijs-backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wikijs" "requarks/wiki" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

    msg_info "Restoring Data"
    cp -R /opt/wikijs-backup/* /opt/wikijs
    $SQLITE_INSTALL && $STD npm rebuild sqlite3
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start wikijs
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -rf /opt/wikijs-backup
    msg_ok "Cleanup Completed"
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
