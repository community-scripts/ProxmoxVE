#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Kometa-Team/Kometa

APP="Kometa"
var_tags="${var_tags:-media;streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d "/opt/kometa" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "kometa" "Kometa-Team/Kometa"; then
    msg_info "Stopping Service"
    systemctl stop kometa
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    cp /opt/kometa/config/config.yml /opt
    msg_ok "Backup completed"

    PYTHON_VERSION="3.13" setup_uv
    fetch_and_deploy_gh_release "kometa" "Kometa-Team/Kometa"

    msg_info "Updating Kometa"
    $STD uv pip install -r requirements.txt --system
    mkdir -p config/assets
    cp /opt/config.yml config/config.yml
    msg_ok "Updated Kometa"

    msg_info "Starting Service"
    systemctl start kometa
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the LXC at following IP address:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}${CL}"
