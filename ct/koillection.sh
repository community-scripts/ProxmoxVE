#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koillection.github.io/

APP="Koillection"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/koillection ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "koillection" "benjaminjonard/koillection"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Creating a backup"
    mv /opt/koillection/ /opt/koillection-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "koillection" "benjaminjonard/koillection"

    msg_info "Updating ${APP}"
    cd /opt/koillection
    cp -r /opt/koillection-backup/.env.local /opt/koillection
    cp -r /opt/koillection-backup/public/uploads/. /opt/koillection/public/uploads/
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev -o --no-interaction --classmap-authoritative
    $STD php bin/console doctrine:migrations:migrate --no-interaction
    $STD php bin/console app:translations:dump
    cd assets/
    $STD yarn install
    $STD yarn build
    chown -R www-data:www-data /opt/koillection/public/uploads
    msg_ok "Updated $APP"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r /opt/koillection-backup
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
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
