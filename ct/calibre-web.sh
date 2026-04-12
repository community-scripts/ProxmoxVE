#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: mikolaj92
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/janeczku/calibre-web

APP="calibre-web"
var_tags="${var_tags:-media;books}"
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

  if [[ ! -d /opt/calibre-web ]]; then
    msg_error "No Calibre-Web Installation Found!"
    exit
  fi

  if check_for_gh_release "Calibre-Web" "janeczku/calibre-web"; then
    msg_info "Stopping Service"
    systemctl stop calibre-web
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/calibre-web/app.db /opt/app.db_backup
    cp -r /opt/calibre-web/data /opt/data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Calibre-Web" "janeczku/calibre-web" "prebuild" "latest" "/opt/calibre-web" "calibre-web*.tar.gz"
    setup_uv

    msg_info "Installing Dependencies"
    cd /opt/calibre-web
    $STD uv venv
    $STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir --upgrade pip setuptools wheel
    $STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir -r requirements.txt
    msg_ok "Installed Dependencies"

    msg_info "Restoring Data"
    cp /opt/app.db_backup /opt/calibre-web/app.db 2>/dev/null
    cp -r /opt/data_backup /opt/calibre-web/data 2>/dev/null
    rm -rf /opt/app.db_backup /opt/data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start calibre-web
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8083${CL}"
