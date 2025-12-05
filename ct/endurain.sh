#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: johanngrobe
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/joaovitoriasilva/endurain

APP="Endurain"
var_tags="${var_tags:-sport;social-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

  if [[ ! -d /opt/endurain ]]; then
    msg_error "No ${APP} installation found!"
    exit 1
  fi
  if check_for_gh_release "endurain" "joaovitoriasilva/endurain"; then
    msg_info "Stopping Service"
    systemctl stop endurain
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/endurain/.env /opt/endurain.env
    cp /opt/endurain/frontend/app/dist/env.js /opt/endurain.env.js
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "endurain" "joaovitoriasilva/endurain" "tarball" "latest" "/opt/endurain"

    msg_info "Preparing Update"
    cd /opt/endurain
    rm -rf \
      /opt/endurain/{docs,example.env,screenshot_01.png} \
      /opt/endurain/docker* \
      /opt/endurain/*.yml
    cp /opt/endurain.env /opt/endurain/.env
    rm /opt/endurain.env
    msg_ok "Prepared Update"

    msg_info "Updating Frontend"
    cd /opt/endurain/frontend/app
    $STD npm ci
    $STD npm run build
    cp /opt/endurain.env.js /opt/endurain/frontend/app/dist/env.js
    rm /opt/endurain.env.js
    msg_ok "Updated Frontend"

    msg_info "Updating Backend"
    cd /opt/endurain/backend
    $STD poetry export -f requirements.txt --output requirements.txt --without-hashes
    $STD uv venv
    $STD uv pip install -r requirements.txt
    msg_ok "Backend Updated"

    msg_info "Starting Service"
    systemctl start endurain
    msg_ok "Started Service"
    msg_ok "Update Completed Successfully!"
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
