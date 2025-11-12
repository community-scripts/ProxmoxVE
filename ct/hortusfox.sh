#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danielbrendel/hortusfox-web

APP="HortusFox"
var_tags="${var_tags:-plants}"
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
  if [[ ! -d /opt/hortusfox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "hortusfox" "danielbrendel/hortusfox-web"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Backing up current HortusFox installation"
    cd /opt
    mv /opt/hortusfox/ /opt/hortusfox-backup
    msg_ok "Backed up current HortusFox installation"

    fetch_and_deploy_gh_release "hortusfox" "danielbrendel/hortusfox-web"

    msg_info "Updating HortusFox"
    cd /opt/hortusfox
    mv /opt/hortusfox-backup/.env /opt/hortusfox/.env
    $STD composer install --no-dev --optimize-autoloader
    $STD php asatru migrate --no-interaction
    $STD php asatru plants:attributes
    $STD php asatru calendar:classes
    chown -R www-data:www-data /opt/hortusfox
    rm -r /opt/hortusfox-backup
    msg_ok "Updated HortusFox"

    msg_info "Starting Service"
    systemctl start apache2
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
