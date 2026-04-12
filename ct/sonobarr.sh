#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: GoldenSpringness
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dodelidoo-Labs/sonobarr

APP="sonobarr"
var_tags="${var_tags:-music;discovery}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d "/opt/sonobarr" ]]; then
    msg_error "No sonobarr Installation Found!"
    exit
  fi

  PYTHON_VERSION="3.12" setup_uv

  if check_for_gh_release "sonobarr" "Dodelidoo-Labs/sonobarr"; then
    msg_info "Stopping Service"
    systemctl stop sonobarr
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sonobarr" "Dodelidoo-Labs/sonobarr" "tarball"

    msg_info "Updating sonobarr"
    $STD uv venv -c /opt/sonobarr/venv
    $STD source /opt/sonobarr/venv/bin/activate
    $STD uv pip install --no-cache-dir -r /opt/sonobarr/requirements.txt
    sed -i "/release_version/s/=.*/=$(cat ~/.sonobarr)/" /etc/sonobarr/.env
    msg_ok "Updated sonobarr"

    msg_info "Starting Service"
    systemctl start sonobarr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}sonobarr setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
