#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

# App Default Values
APP="Kimai"
var_tags="time-tracking"
var_cpu="2"
var_ram="2048"
var_disk="7"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/kimai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/kimai/kimai/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    msg_info "Updating ${APP} to ${RELEASE}"
    cp /opt/kimai/.env /opt/.env
    rm -rf /opt/kimai
    wget -q "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip"
    unzip -q ${RELEASE}.zip
    mv kimai-${RELEASE} /opt/kimai
    mv /opt/.env /opt/kimai/.env
    cd /opt/kimai
    composer install --no-dev --optimize-autoloader &>/dev/null
    bin/console kimai:update &>/dev/null
    chown -R :www-data .
    chmod -R g+r .
    chmod -R g+rw var/
    sudo chown -R www-data:www-data /opt/kimai
    sudo chmod -R 755 /opt/kimai
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Cleaning Up"
    rm -rf ${RELEASE}.zip
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
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