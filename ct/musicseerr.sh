#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://musicseerr.com/ | Github: https://github.com/HabiRabbu/Musicseerr

APP="MusicSeerr"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/musicseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "musicseerr" "HabiRabbu/Musicseerr"; then
    msg_info "Stopping Service"
    systemctl stop musicseerr
    msg_ok "Stopped Service"

    create_backup /opt/musicseerr/backend/config /opt/musicseerr/backend/cache

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "musicseerr" "HabiRabbu/Musicseerr" "tarball"
    restore_backup
    NODE_VERSION="25" NODE_MODULE="pnpm@10.33.0" setup_nodejs

    msg_info "Building Frontend"
    cd /opt/musicseerr/frontend
    export NODE_OPTIONS="--max-old-space-size=3072"
    rm -rf node_modules build
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    msg_ok "Built Frontend"

    msg_info "Updating Application"
    mkdir -p /opt/musicseerr/backend/config /opt/musicseerr/backend/cache
    $STD uv venv --clear /opt/musicseerr/venv
    $STD uv pip install -r /opt/musicseerr/backend/requirements.txt --python=/opt/musicseerr/venv/bin/python
    rm -rf /opt/musicseerr/backend/static
    cp -r /opt/musicseerr/frontend/build /opt/musicseerr/backend/static
    msg_ok "Updated Application"


    msg_info "Starting Service"
    systemctl start musicseerr
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8688${CL}"
