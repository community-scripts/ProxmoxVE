#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/LycheeOrg/Lychee

APP="Lychee"
var_tags="${var_tags:-media;photos;gallery}"
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

  if [[ ! -d /opt/lychee ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "lychee" "LycheeOrg/Lychee"; then
    msg_info "Stopping Services"
    systemctl stop caddy
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/lychee/.env /opt/lychee.env.bak
    cp -r /opt/lychee/storage /opt/lychee_storage_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lychee" "LycheeOrg/Lychee" "prebuild" "latest" "/opt/lychee" "Lychee.zip"

    msg_info "Restoring Data"
    cp /opt/lychee.env.bak /opt/lychee/.env
    rm -f /opt/lychee.env.bak
    cp -r /opt/lychee_storage_backup/. /opt/lychee/storage
    rm -rf /opt/lychee_storage_backup
    msg_ok "Restored Data"

    msg_info "Updating Application"
    cd /opt/lychee
    $STD php artisan migrate --force
    $STD php artisan optimize:clear
    chmod -R 775 /opt/lychee/storage /opt/lychee/bootstrap/cache
    msg_ok "Updated Application"

    msg_info "Starting Services"
    systemctl start caddy
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
