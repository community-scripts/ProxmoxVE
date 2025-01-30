#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Don Locke (DonLocke)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wavelog.org/

# App Default Values
APP="Wavelog"
var_tags="radio-logging"
var_cpu="1"
var_ram="512"
var_disk="2"
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
  if [[ ! -d /opt/wavelog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/wavelog/wavelog/releases/latest | grep "tag_name" | cut -d '"' -f 4)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Services"
    systemctl stop apache2
    msg_ok "Services Stopped"

    msg_info "Updating ${APP} to ${RELEASE}"
    cp /opt/wavelog/application/config/config.php /opt/config.php
    cp /opt/wavelog/application/config/database.php /opt/database.php
    cp -r /opt/wavelog/userdata /opt/userdata
    if [[ -f /opt/wavelog/assets/js/sections/custom.js ]]; then
      cp /opt/wavelog/assets/js/sections/custom.js /opt/custom.js
    fi
    wget -q "https://github.com/wavelog/wavelog/archive/refs/tags/${RELEASE}.zip"
    unzip -q ${RELEASE}.zip
    rm -rf /opt/wavelog
    mv wavelog-${RELEASE}/ /opt/wavelog
    rm -rf /opt/wavelog/install
    mv /opt/config.php /opt/wavelog/application/config/config.php
    mv /opt/database.php /opt/wavelog/application/config/database.php
    cp -r /opt/userdata/* /opt/wavelog/userdata
    rm -rf /opt/userdata
    if [[ -f /opt/custom.js ]]; then
      mv /opt/custom.js /opt/wavelog/assets/js/sections/custom.js
    fi
    chown -R www-data:www-data /opt/wavelog/
    find /opt/wavelog/ -type d -exec chmod 755 {} \;
    find /opt/wavelog/ -type f -exec chmod 664 {} \;
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start apache2
    msg_ok "Started Services"

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