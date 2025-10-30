#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HabitRPG/habitica

APP="Habitica"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/habitica" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  NODE_VERSION="20" NODE_MODULE="gulp-cli,mocha" setup_nodejs
  if check_for_gh_release "habitica" "HabitRPG/habitica"; then
    msg_info "Stopping Service"
    systemctl stop habitica-mongodb
    systemctl stop habitica
    systemctl stop habitica-client
    msg_info "Stopped Service"

    msg_info "Save configuration"
    if [[ -f /opt/habitica/config.json ]]; then
      cp /opt/habitica/config.json ~/config.json
      msg_ok "Saved configuration"
    else
      msg_warn "No configuration file found, skipping save"
    fi

    fetch_and_deploy_gh_release "habitica" "HabitRPG/habitica" "tarball" "latest" "/opt/habitica"

    msg_info "Updating $APP"
    cd /opt/habitica
    $STD npm i
    $STD npm run postinstall
    $STD npm run client:build
    $STD gulp build:prod
    msg_ok "Updated $APP"

    msg_info "Restoring configuration"
    if [[ -f ~/config.json ]]; then
      cp ~/config.json /opt/habitica/config.json
      msg_ok "Restored configuration"
    else
      msg_warn "No configuration file found to restore"
    fi

    msg_info "Starting Service"
    systemctl start habitica-mongodb
    systemctl start habitica
    systemctl start habitica-client
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
