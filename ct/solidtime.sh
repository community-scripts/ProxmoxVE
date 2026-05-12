#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.solidtime.io/

APP="SolidTime"
var_tags="${var_tags:-time-tracking;productivity;business}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/solidtime ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "solidtime" "solidtime-io/solidtime"; then
    msg_info "Stopping Services"
    systemctl stop caddy
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/solidtime/.env /opt/solidtime.env.bak
    cp -r /opt/solidtime/storage /opt/solidtime_storage_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "solidtime" "solidtime-io/solidtime" "tarball"

    msg_info "Restoring Data"
    cp /opt/solidtime.env.bak /opt/solidtime/.env
    rm -f /opt/solidtime.env.bak
    cp -r /opt/solidtime_storage_backup/. /opt/solidtime/storage
    rm -rf /opt/solidtime_storage_backup
    msg_ok "Restored Data"

    msg_info "Updating Application"
    cd /opt/solidtime
    $STD composer install --no-dev --optimize-autoloader
    $STD npm install
    $STD npm run build
    $STD php artisan migrate --force
    $STD php artisan optimize:clear
    chown -R www-data:www-data /opt/solidtime
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
echo -e "${INFO}${YW}HTTPS is not enabled by default (use domain + reverse proxy/TLS if needed).${CL}"
