#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snipeitapp.com/

APP="SnipeIT"
var_tags="${var_tags:-asset-management;foss}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

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
  if ! grep -q "client_max_body_size[[:space:]]\+100M;" /etc/nginx/conf.d/snipeit.conf; then
    sed -i '/index index.php;/i \        client_max_body_size 100M;' /etc/nginx/conf.d/snipeit.conf
  fi

  if check_for_gh_release "snipe-it" "snipe/snipe-it"; then
    msg_info "Stopping Services"
    systemctl stop nginx
    msg_ok "Services Stopped"

    msg_info "Creating backup"
    mv /opt/snipe-it /opt/snipe-it-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "snipe-it" "snipe/snipe-it" "tarball"
    [[ "$(php -v 2>/dev/null)" == PHP\ 8.2* ]] && PHP_VERSION="8.3" PHP_MODULE="common,ctype,ldap,fileinfo,iconv,mysql,soap,xsl" PHP_FPM="YES" setup_php
    sed -i 's/php8.2/php8.3/g' /etc/nginx/conf.d/snipeit.conf
    setup_composer

    msg_info "Updating ${APP}"
    $STD apt-get update
    $STD apt-get -y upgrade
    cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
    cp -r /opt/snipe-it-backup/public/uploads/ /opt/snipe-it/public/uploads/
    cp -r /opt/snipe-it-backup/storage/private_uploads /opt/snipe-it/storage/private_uploads
    cd /opt/snipe-it/
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD composer dump-autoload
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan route:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    chown -R www-data: /opt/snipe-it
    chmod -R 755 /opt/snipe-it
    rm -rf /opt/snipe-it-backup
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start nginx
    msg_ok "Started Service"
    msg_ok "Update Successful"
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
