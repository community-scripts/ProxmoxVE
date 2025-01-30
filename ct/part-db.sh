#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.part-db.de/

# App Default Values
APP="Part-DB"
var_tags="inventory;parts"
var_cpu="2"
var_ram="1024"
var_disk="8"
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
  if [[ ! -d /opt/partdb ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/Part-DB/Part-DB-server/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Updating $APP to v${RELEASE}"
    cd /opt
    mv /opt/partdb/ /opt/partdb-backup
    wget -q "https://github.com/Part-DB/Part-DB-server/archive/refs/tags/v${RELEASE}.zip"
    unzip -q "v${RELEASE}.zip"
    mv /opt/Part-DB-server-${RELEASE}/ /opt/partdb

    cd /opt/partdb/
    cp -r "/opt/partdb-backup/.env.local" /opt/partdb/
    cp -r "/opt/partdb-backup/public/media" /opt/partdb/public/
    cp -r "/opt/partdb-backup/config/banner.md" /opt/partdb/config/

    export COMPOSER_ALLOW_SUPERUSER=1
    composer install --no-dev -o --no-interaction &>/dev/null
    yarn install &>/dev/null
    yarn build &>/dev/null
    php bin/console cache:clear &>/dev/null
    php bin/console doctrine:migrations:migrate -n &>/dev/null
    chown -R www-data:www-data /opt/partdb
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r "/opt/v${RELEASE}.zip"
    rm -r /opt/partdb-backup
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
