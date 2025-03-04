#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pelican-dev/panel

APP="Pelican-Panel"
var_tags="Gaming"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pelican-panel ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/pelican-dev/panel/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    cd /opt/pelican-panel
    $STD php artisan down
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cp -r /opt/pelican-panel/.env /opt/
    rm -rf * .*
    wget -q "https://github.com/pelican-dev/panel/releases/download/v${RELEASE}/panel.tar.gz"
    tar -xzf "panel.tar.gz"
    mv /opt/.env /opt/pelican-panel/
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD php artisan p:environment:setup
    $STD php artisan view:clear
    $STD php artisan config:clear
    $STD php artisan filament:optimize
    $STD php artisan migrate --seed --force
    chown -R www-data:www-data /opt/pelican-panel
    chmod -R 755 /opt/pelican-panel/storage /opt/pelican-panel/bootstrap/cache/
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    $STD php artisan queue:restart
    $STD php artisan up
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf "/opt/pelican-panel/panel.tar.gz"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/installer${CL}"
