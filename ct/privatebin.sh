#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://privatebin.info/

APP="PrivateBin"
var_tags="${var_tags:-paste;secure}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/privatebin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "privatebin" "PrivateBin/PrivateBin"; then
    msg_info "Creating backup"
    cp -f /opt/privatebin/cfg/conf.php /tmp/privatebin_conf.bak
    msg_ok "Backup created"

    rm -rf /opt/privatebin/*
    fetch_and_deploy_gh_release "privatebin" "PrivateBin/PrivateBin" "tarball"

    msg_info "Configuring ${APP}"
    mkdir -p /opt/privatebin/data
    mv /tmp/privatebin_conf.bak /opt/privatebin/cfg/conf.php
    chown -R www-data:www-data /opt/privatebin
    chmod -R 0755 /opt/privatebin/data
    systemctl reload nginx php8.2-fpm
    msg_ok "Configured ${APP}"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
