#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: snazzybean
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TomBursch/kitchenowl

APP="KitchenOwl"
var_tags="${var_tags:-food;recipes}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/kitchenowl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kitchenowl" "TomBursch/kitchenowl"; then
    msg_info "Stopping Service"
    systemctl stop kitchenowl
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/kitchenowl_backup
    cp -r /opt/kitchenowl/data /opt/kitchenowl_backup/
    cp -f /opt/kitchenowl/kitchenowl.env /opt/kitchenowl_backup/
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kitchenowl" "TomBursch/kitchenowl" "tarball" "latest" "/opt/kitchenowl"
    rm -rf /opt/kitchenowl/web
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kitchenowl-web" "TomBursch/kitchenowl" "prebuild" "latest" "/opt/kitchenowl/web" "kitchenowl_Web.tar.gz"

    msg_info "Restoring data"
    sed -i 's/default=True/default=False/' /opt/kitchenowl/backend/wsgi.py
    cp -r /opt/kitchenowl_backup/data /opt/kitchenowl/
    cp -f /opt/kitchenowl_backup/kitchenowl.env /opt/kitchenowl/
    rm -rf /opt/kitchenowl_backup
    msg_ok "Restored data"

    msg_info "Updating KitchenOwl"
    cd /opt/kitchenowl/backend
    $STD uv sync --frozen
    cd /opt/kitchenowl/backend
    set -a
    source /opt/kitchenowl/kitchenowl.env
    set +a
    $STD uv run flask db upgrade
    msg_ok "Updated KitchenOwl"

    msg_info "Starting Service"
    systemctl start kitchenowl
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
