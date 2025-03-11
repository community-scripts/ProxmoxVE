#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snipeitapp.com/

APP="SnipeIT"
var_tags="asset-management;foss"
var_cpu="2"
var_ram="2048"
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
  if [[ ! -d /opt/snipe-it ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/snipe/snipe-it/releases/latest | grep '"tag_name"' | sed -E 's/.*"tag_name": "v([^"]+).*/\1/')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Services"
    systemctl stop nginx
    msg_ok "Services Stopped"
    
    msg_info "Updating ${APP} to v${RELEASE}"
    $STD apt-get update
    $STD apt-get -y upgrade
    mv /opt/snipe-it /opt/snipe-it-backup
    temp_file=$(mktemp)
    wget -q "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
    tar zxf $temp_file
    mv snipe-it-${RELEASE} /opt/snipe-it
    $STD wget -q "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip"
    unzip -q v${RELEASE}.zip
    mv snipe-it-${RELEASE} /opt/snipe-it
    cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
    cp -r /opt/snipe-it-backup/public/uploads/ /opt/snipe-it/public/uploads/
    cp -r /opt/snipe-it-backup/storage/private_uploads /opt/snipe-it/storage/private_uploads
    cd /opt/snipe-it/
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --prefer-source
    $STD composer dump-autoload
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan route:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    chown -R www-data: /opt/snipe-it
    chmod -R 755 /opt/snipe-it
    rm -rf /opt/v${RELEASE}.zip
    rm -rf /opt/snipe-it-backup
    msg_ok "Updated ${APP}"
    
    msg_info "Starting Service"
    systemctl start nginx
    msg_ok "Started Service"
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
