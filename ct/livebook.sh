#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: dkuku
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/livebook-dev/livebook

APP="Livebook"
var_tags="${var_tags:-development}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/livebook/.mix/escripts/livebook ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "livebook" "livebook-dev/livebook"; then
    msg_info "Stopping Service"
    systemctl stop livebook
    msg_info "Stopped Service"

    msg_info "Updating Container"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Updated Container"

    msg_info "Updating Livebook"
    source /opt/livebook/.env
    cd /opt/livebook
    $STD mix escript.install hex livebook --force

    chown -R livebook:livebook /opt/livebook /data

    msg_info "Starting Service"
    systemctl start livebook
    msg_info "Started Service"

    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
