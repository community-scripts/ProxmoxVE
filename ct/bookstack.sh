#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BookStackApp/BookStack

APP="Bookstack"
var_tags="${var_tags:-organizer}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/bookstack ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "bookstack" "BookStackApp/BookStack"; then
    msg_info "Stopping Apache2"
    systemctl stop apache2
    msg_ok "Services Stopped"

    msg_info "Backing up data"
    mv /opt/bookstack /opt/bookstack-backup
    msg_ok "Backup finished"

    fetch_and_deploy_gh_release "bookstack" "BookStackApp/BookStack"
    PHP_MODULE="ldap,tidy,bz2,mysqli" PHP_FPM="YES" PHP_APACHE="YES" PHP_VERSION="8.3" setup_php
    setup_composer

    msg_info "Restoring backup"
    cp /opt/bookstack-backup/.env /opt/bookstack/.env
    [[ -d /opt/bookstack-backup/public/uploads ]] && cp -a /opt/bookstack-backup/public/uploads/. /opt/bookstack/public/uploads/
    [[ -d /opt/bookstack-backup/storage/uploads ]] && cp -a /opt/bookstack-backup/storage/uploads/. /opt/bookstack/storage/uploads/
    [[ -d /opt/bookstack-backup/themes ]] && cp -a /opt/bookstack-backup/themes/. /opt/bookstack/themes/
    msg_ok "Backup restored"

    msg_info "Configuring BookStack"
    cd /opt/bookstack
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev
    $STD php artisan migrate --force
    chown www-data:www-data -R /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
    chmod -R 755 /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
    chmod -R 775 /opt/bookstack/storage /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads
    chmod -R 640 /opt/bookstack/.env
    msg_ok "Configured BookStack"

    msg_info "Starting Apache2"
    systemctl start apache2
    msg_ok "Started Apache2"

    msg_info "Cleaning Up"
    rm -rf /opt/bookstack-backup
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
