#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Benito Rodríguez (b3ni)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/investbrainapp/investbrain

APP="Investbrain"
var_tags="${var_tags:-finance;portfolio;investing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/investbrain ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Investbrain" "investbrainapp/investbrain"; then
    PHP_VERSION="8.4"
    msg_info "Stopping Services"
    systemctl stop nginx php${PHP_VERSION}-fpm
    $STD supervisorctl stop all
    msg_ok "Services Stopped"

    PHP_FPM=YES PHP_MODULE="gd,zip,intl,pdo,pgsql,pdo-pgsql,bcmath,opcache,mbstring,redis" setup_php
    setup_composer
    NODE_VERSION="22" setup_nodejs
    PG_VERSION="17" setup_postgresql

    msg_info "Creating Backup"
    rm -f /opt/.env.backup
    rm -rf /opt/investbrain_backup
    cp /opt/investbrain/.env /opt/.env.backup
    cp -r /opt/investbrain/storage /opt/investbrain_backup
    msg_ok "Created Backup"

    fetch_and_deploy_gh_release "Investbrain" "investbrainapp/investbrain" "tarball" "latest" "/opt/investbrain"

    msg_info "Updating Investbrain"
    cd /opt/investbrain
    rm -rf /opt/investbrain/storage
    cp /opt/.env.backup /opt/investbrain/.env
    cp -r /opt/investbrain_backup/ /opt/investbrain/storage
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD /usr/local/bin/composer install --no-interaction --no-dev --optimize-autoloader
    $STD npm install
    $STD npm run build
    $STD php artisan storage:link
    $STD php artisan migrate --force
    $STD php artisan cache:clear
    $STD php artisan view:clear
    $STD php artisan route:clear
    $STD php artisan event:clear
    $STD php artisan route:cache
    $STD php artisan event:cache
    chown -R www-data:www-data /opt/investbrain
    chmod -R 775 /opt/investbrain/storage /opt/investbrain/bootstrap/cache
    rm -rf /opt/.env.backup /opt/investbrain_backup
    msg_ok "Updated Investbrain"

    msg_info "Starting Services"
    systemctl start php${PHP_VERSION}-fpm nginx
    $STD supervisorctl start all
    msg_ok "Services Started"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
