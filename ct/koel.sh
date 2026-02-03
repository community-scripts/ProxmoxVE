#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koel.dev/

APP="Koel"
var_tags="${var_tags:-music;streaming}"
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

  if [[ ! -d /opt/koel ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "koel" "koel/koel"; then
    msg_info "Stopping Services"
    systemctl stop nginx php8.4-fpm
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    mkdir -p /tmp/koel_backup
    cp /opt/koel/.env /tmp/koel_backup/
    cp -r /opt/koel/storage /tmp/koel_backup/ 2>/dev/null || true
    cp -r /opt/koel/public/img /tmp/koel_backup/ 2>/dev/null || true
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "koel" "koel/koel" "prebuild" "latest" "/opt/koel" "koel-*.tar.gz"

    msg_info "Restoring Data"
    cp /tmp/koel_backup/.env /opt/koel/
    cp -r /tmp/koel_backup/storage/* /opt/koel/storage/ 2>/dev/null || true
    cp -r /tmp/koel_backup/img/* /opt/koel/public/img/ 2>/dev/null || true
    rm -rf /tmp/koel_backup
    msg_ok "Restored Data"

    msg_info "Running Migrations"
    cd /opt/koel 
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-interaction --no-dev --optimize-autoloader
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    $STD php artisan koel:init --no-assets --no-interaction
    chown -R www-data:www-data /opt/koel
    chmod -R 775 /opt/koel/storage
    msg_ok "Ran Migrations"

    msg_info "Starting Services"
    systemctl start php8.4-fpm nginx
    msg_ok "Started Services"
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
