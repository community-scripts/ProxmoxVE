#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: BiluliB
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plexguide/Huntarr.io

APP="huntarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /opt/huntarr/main.py ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_uv

  if check_for_gh_release "huntarr" "plexguide/Huntarr.io"; then
    msg_info "Stopping huntarr"
    systemctl stop huntarr
    msg_ok "Stopped huntarr"

    fetch_and_deploy_gh_release "huntarr" "plexguide/Huntarr.io"

    msg_info "Configuring $APP"
    cd /opt/huntarr
    $STD uv pip install -r requirements.txt --python /opt/huntarr/.venv/bin/python
    msg_ok "Configured $APP"

    msg_info "Starting $APP"
    systemctl start huntarr
    msg_ok "Started $APP"
    msg_ok "Updated $APP"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9705${CL}"
