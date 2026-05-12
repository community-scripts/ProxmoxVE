#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://shlink.io/

APP="Shlink"
var_tags="${var_tags:-url-shortener;analytics;php}"
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

  if [[ ! -d /opt/shlink ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "shlink" "shlinkio/shlink"; then
    msg_info "Stopping Service"
    systemctl stop shlink
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/shlink/.env /opt/shlink.env.bak
    cp -r /opt/shlink/data /opt/shlink_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "shlink" "shlinkio/shlink" "prebuild" "latest" "/opt/shlink" "shlink*_php8.5_dist.zip"

    msg_info "Restoring Data"
    cp /opt/shlink.env.bak /opt/shlink/.env
    rm -f /opt/shlink.env.bak
    cp -r /opt/shlink_data_backup/. /opt/shlink/data
    rm -rf /opt/shlink_data_backup
    msg_ok "Restored Data"

    msg_info "Updating Application"
    cd /opt/shlink
    $STD php ./vendor/bin/rr get --no-interaction --location bin/
    chmod +x bin/rr
    set -a
    source /opt/shlink/.env
    set +a
    $STD php vendor/bin/shlink-installer init --no-interaction --clear-db-cache --skip-download-geolite
    msg_ok "Updated Application"

    msg_info "Starting Service"
    systemctl start shlink
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi

  if [[ -d /opt/shlink-web-client ]]; then
    if check_for_gh_release "shlink-web-client" "shlinkio/shlink-web-client"; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "shlink-web-client" "shlinkio/shlink-web-client" "prebuild" "latest" "/opt/shlink-web-client" "shlink-web-client_*_dist.zip"
      msg_ok "Updated Web Client"
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access Shlink Web Client using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW} Shlink HTTP API:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
