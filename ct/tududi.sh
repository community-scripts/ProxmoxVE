#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com

APP="Tududi"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/tududi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "tududi" "chrisvel/tududi"; then
    msg_info "Stopping Service"
    systemctl stop tududi
    msg_ok "Stopped Service"

    msg_info "Backing up env file"
    if [[ -f /opt/tududi/backend/.env ]]; then
      cp /opt/tududi/backend/.env /opt/tududi.env
    else
      cp /opt/tududi/.env /opt/tududi.env
    fi
    msg_ok "Backed up env file"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tududi" "chrisvel/tududi" "tarball" "latest" "/opt/tududi"

    msg_info "Updating Tududi"
    cd /opt/tududi
    $STD npm install
    export NODE_ENV=production
    $STD npm run frontend:build
    mv ./dist ./backend
    mv /opt/tududi.env /opt/tududi/backend/.env
    DB="$(sed -n '/^DB_FILE/s/[^=]*=//p' /opt/tududi/backend/.env)"
    export DB_FILE="$DB"
    sed -i -e 's|/tududi$|/tududi/backend|' \
      -e 's|npm run start|bash /opt/tududi/backend/cmd/start.sh|' \
      /etc/systemd/system/tududi.service
    systemctl daemon-reload
    msg_ok "Updated Tududi"

    msg_info "Starting Service"
    systemctl start tududi
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3002${CL}"
