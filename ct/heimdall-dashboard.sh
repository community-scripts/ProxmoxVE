#!/usr/bin/env bash
: "${CSCRIPTS_BASE_URL:=https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -s "${CSCRIPTS_BASE_URL}/misc/build.func")
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://heimdall.site/

# App Default Values
APP="Heimdall-Dashboard"
var_tags="dashboard"
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
  if [[ ! -d /opt/Heimdall ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -sX GET "https://api.github.com/repos/linuxserver/Heimdall/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop heimdall
    sleep 1
    msg_ok "Stopped ${APP}"
    msg_info "Backing up Data"
    cp -R /opt/Heimdall/database database-backup
    cp -R /opt/Heimdall/public public-backup
    sleep 1
    msg_ok "Backed up Data"
    msg_info "Updating Heimdall Dashboard to ${RELEASE}"
    wget -q https://github.com/linuxserver/Heimdall/archive/${RELEASE}.tar.gz
    tar xzf ${RELEASE}.tar.gz
    VER=$(curl -s https://api.github.com/repos/linuxserver/Heimdall/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    cp -R Heimdall-${VER}/* /opt/Heimdall
    cd /opt/Heimdall
    apt-get install -y composer &>/dev/null
    COMPOSER_ALLOW_SUPERUSER=1 composer dump-autoload &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Heimdall Dashboard to ${RELEASE}"
    msg_info "Restoring Data"
    cd ~
    cp -R database-backup/* /opt/Heimdall/database
    cp -R public-backup/* /opt/Heimdall/public
    sleep 1
    msg_ok "Restored Data"
    msg_info "Cleanup"
    rm -rf {${RELEASE}.tar.gz,Heimdall-${VER},public-backup,database-backup,Heimdall}
    sleep 1
    msg_ok "Cleaned"
    msg_info "Starting ${APP}"
    systemctl start heimdall.service
    sleep 2
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7990${CL}"