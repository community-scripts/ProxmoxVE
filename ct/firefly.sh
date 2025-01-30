#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: quantumryuu
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://firefly-iii.org/

# App Default Values
APP="Firefly"
var_tags="finance"
var_cpu="1"
var_ram="1024"
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

  if [[ ! -d /opt/firefly ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/firefly-iii/firefly-iii/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Stopped Apache2"

    msg_info "Updating ${APP} to v${RELEASE}"
    cp /opt/firefly/.env /opt/.env
    cp -r /opt/firefly/storage /opt/storage
    rm -rf /opt/firefly/*
    cd /opt
    wget -q "https://github.com/firefly-iii/firefly-iii/releases/download/v${RELEASE}/FireflyIII-v${RELEASE}.tar.gz"
    tar -xzf FireflyIII-v${RELEASE}.tar.gz -C /opt/firefly --exclude='storage'
    cd /opt/firefly 
    composer install --no-dev --no-interaction &>/dev/null
    php artisan migrate --seed --force &>/dev/null
    php artisan firefly:decrypt-all &>/dev/null
    php artisan cache:clear &>/dev/null
    php artisan view:clear &>/dev/null
    php artisan firefly:upgrade-database &>/dev/null
    php artisan firefly:laravel-passport-keys &>/dev/null
    chown -R www-data:www-data /opt/firefly
    chmod -R 775 /opt/firefly/storage

    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Cleaning up"
    rm -rf /opt/FireflyIII-v${RELEASE}.tar.gz
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
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