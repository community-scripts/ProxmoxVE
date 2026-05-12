#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Nezreka/SoulSync

APP="SoulSync"
var_tags="${var_tags:-music;automation;media}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -f ~/.soulsync ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "soulsync" "Nezreka/SoulSync"; then
    msg_info "Stopping Service"
    systemctl stop soulsync
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    mv /opt/soulsync/config /opt/soulsync-config.bak
    mv /opt/soulsync/data /opt/soulsync-data.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "soulsync" "Nezreka/SoulSync" "tarball"

    msg_info "Updating Python Dependencies"
    cd /opt/soulsync
    $STD uv venv --clear /opt/soulsync/.venv --python 3.11
    $STD /opt/soulsync/.venv/bin/pip install -r requirements.txt
    msg_ok "Updated Python Dependencies"

    mv /opt/soulsync-config.bak /opt/soulsync/config
    mv /opt/soulsync-data.bak /opt/soulsync/data

    msg_info "Starting Service"
    systemctl start soulsync
    msg_ok "Started Service"
    msg_ok "Updated ${APP}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8008${CL}"
