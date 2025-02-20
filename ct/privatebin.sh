#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://privatebin.info/

APP="PrivateBin"
var_tags="paste;secure"
var_cpu="1"
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
  if [[ ! -d /opt/privatebin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/PrivateBin/PrivateBin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    echo "${RELEASE}" >/opt/${APP}_version.txt
    cp -f /opt/privatebin/cfg/conf.php /tmp/privatebin_conf.bak
    wget -q "https://github.com/PrivateBin/PrivateBin/archive/refs/tags/${RELEASE}.zip"
    unzip -q ${RELEASE}.zip
    rm -rf /opt/privatebin/*
    mv PrivateBin-${RELEASE}/* /opt/privatebin/
    mv /tmp/privatebin_conf.bak /opt/privatebin/cfg/conf.php
    chown -R www-data:www-data /opt/privatebin
    chmod -R 0755 /opt/privatebin/data
    echo "${RELEASE}" >/opt/${APP}_version.txt
    rm -rf ${RELEASE}.zip PrivateBin-${RELEASE}
    systemctl reload nginx php8.2-fpm
    msg_ok "Updated ${APP} to v${RELEASE}"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
