#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | DevelopmentCats | AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://romm.app

APP="RomM"
var_tags="${var_tags:-emulation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "romm" "rommapp/romm"; then
    msg_info "Stopping Services"
    systemctl stop romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Stopped Services"

    msg_info "Backing up configuration"
    cp /opt/romm/.env /opt/romm/.env.backup
    msg_ok "Backed up configuration"

    fetch_and_deploy_gh_release "romm" "rommapp/romm" "tarball" "latest" "/opt/romm"

    msg_info "Updating ROMM"
    cp /opt/romm/.env.backup /opt/romm/.env
    cd /opt/romm
    $STD uv sync --all-extras
    cd /opt/romm/backend
    $STD uv run alembic upgrade head
    cd /opt/romm/frontend
    $STD npm install
    $STD npm run build
    # Merge static assets into dist folder
    cp -rf /opt/romm/frontend/assets/* /opt/romm/frontend/dist/assets/
    mkdir -p /opt/romm/frontend/dist/assets/romm
    ln -sfn /var/lib/romm/resources /opt/romm/frontend/dist/assets/romm/resources
    ln -sfn /var/lib/romm/assets /opt/romm/frontend/dist/assets/romm/assets
    msg_ok "Updated ROMM"

    msg_info "Starting Services"
    systemctl start romm-backend romm-worker romm-scheduler romm-watcher
    msg_ok "Started Services"
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
