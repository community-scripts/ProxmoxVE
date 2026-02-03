#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.part-db.de/

APP="Part-DB"
var_tags="${var_tags:-inventory;parts}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=80
WEB_UI_PROTOCOL="http"

header_info "$APP"
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
  
  RELEASE=$(get_latest_github_release "Part-DB/Part-DB-server")
  if check_for_gh_release "partdb" "Part-DB/Part-DB-server"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Updating $APP to v${RELEASE}"
    cd /opt
    mv /opt/partdb/ /opt/partdb-backup
    curl -fsSL "https://github.com/Part-DB/Part-DB-server/archive/refs/tags/v${RELEASE}.zip" -o "/opt/v${RELEASE}.zip"
    $STD unzip "v${RELEASE}.zip"
    mv /opt/Part-DB-server-${RELEASE}/ /opt/partdb

    cd /opt/partdb/
    cp -r "/opt/partdb-backup/.env.local" /opt/partdb/
    cp -r "/opt/partdb-backup/public/media" /opt/partdb/public/
    cp -r "/opt/partdb-backup/config/banner.md" /opt/partdb/config/

    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev -o --no-interaction
    $STD yarn install
    $STD yarn build
    $STD php bin/console cache:clear
    $STD php bin/console doctrine:migrations:migrate -n
    chown -R www-data:www-data /opt/partdb
    rm -r "/opt/v${RELEASE}.zip"
    rm -r /opt/partdb-backup
    echo "${RELEASE}" >~/.partdb
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
