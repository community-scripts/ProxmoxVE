#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://magicmirror.builders/

APP="MagicMirror"
var_tags="${var_tags:-smarthome}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
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
  if [[ ! -d /opt/magicmirror ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "magicmirror" "MagicMirrorOrg/MagicMirror"; then
    msg_info "Stopping Service"
    systemctl stop magicmirror
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    rm -rf /opt/magicmirror-backup
    mkdir /opt/magicmirror-backup
    cp /opt/magicmirror/config/config.js /opt/magicmirror-backup
    if [[ -f /opt/magicmirror/css/custom.css ]]; then
      cp /opt/magicmirror/css/custom.css /opt/magicmirror-backup
    fi
    cp -r /opt/magicmirror/modules /opt/magicmirror-backup
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "magicmirror" "MagicMirrorOrg/MagicMirror" "tarball"

    msg_info "Configuring MagicMirror"
    cd /opt/magicmirror
    sed -i -E 's/("postinstall": )".*"/\1""/; s/("prepare": )".*"/\1""/' package.json
    $STD npm run install-mm
    cp /opt/magicmirror-backup/config.js /opt/magicmirror/config/
    if [[ -f /opt/magicmirror-backup/custom.css ]]; then
      cp /opt/magicmirror-backup/custom.css /opt/magicmirror/css/
    fi
    msg_ok "Configured MagicMirror"

    msg_info "Starting Service"
    systemctl start magicmirror
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
