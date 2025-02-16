#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koillection.github.io/

APP="Koillection"
var_tags="network"
var_cpu="2"
var_ram="1024"
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
  if [[ ! -d /opt/koillection ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/benjaminjonard/koillection/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    mv /opt/koillection/ /opt/koillection-backup
    wget -q "https://github.com/benjaminjonard/koillection/archive/refs/tags/${RELEASE}.zip"
    unzip -q "${RELEASE}.zip"
    mv "/opt/koillection-${RELEASE}" /opt/koillection
    cd /opt/koillection
    cp -r /opt/koillection-backup/.env.local /opt/koillection
    cp -r /opt/koillection-backup/public/uploads/. /opt/koillection/public/uploads/
    export COMPOSER_ALLOW_SUPERUSER=1
    composer install --no-dev -o --no-interaction --classmap-authoritative &>/dev/null
    php bin/console doctrine:migrations:migrate --no-interaction &>/dev/null
    php bin/console app:translations:dump &>/dev/null
    cd assets/
    yarn install &>/dev/null
    yarn build &>/dev/null
    chown -R www-data:www-data /opt/koillection/public/uploads
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r "/opt/${RELEASE}.zip"
    rm -r /opt/koillection-backup
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
