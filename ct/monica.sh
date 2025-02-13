#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.monicahq.com/

# App Default Values
APP="Monica"
var_tags="network"
var_cpu="2"
var_ram="2048"
var_disk="8"
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
  if [[ ! -d /opt/monica ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/monicahq/monica/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    mv /opt/monica/ /opt/monica-backup
    wget -q "https://github.com/monicahq/monica/releases/download/v${RELEASE}/monica-v${RELEASE}.tar.bz2"
    tar -xjf "monica-v${RELEASE}.tar.bz2"
    mv "/opt/monica-v${RELEASE}" /opt/monica
    cd /opt/monica/
    cp -r /opt/monica-backup/.env /opt/monica
    cp -r /opt/monica-backup/storage/* /opt/monica/storage/
    composer install --no-interaction --no-dev &>/dev/null
    yarn install &>/dev/null
    yarn run production &>/dev/null
    php artisan monica:update --force &>/dev/null
    chown -R www-data:www-data /opt/monica
    chmod -R 775 /opt/monica/storage
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r "/opt/monica-v${RELEASE}.tar.bz2"
    rm -r /opt/monica-backup
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
