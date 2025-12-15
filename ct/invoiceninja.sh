#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://invoiceninja.com/

APP="InvoiceNinja"
var_tags="${var_tags:-invoicing;business}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/invoiceninja ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "invoiceninja" "invoiceninja/invoiceninja"; then
    msg_info "Stopping Services"
    systemctl stop supervisor nginx php8.4-fpm
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    mkdir -p /tmp/invoiceninja_backup
    cp /opt/invoiceninja/.env /tmp/invoiceninja_backup/
    cp -r /opt/invoiceninja/storage /tmp/invoiceninja_backup/ 2>/dev/null || true
    cp -r /opt/invoiceninja/public/storage /tmp/invoiceninja_backup/public_storage 2>/dev/null || true
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "invoiceninja" "invoiceninja/invoiceninja" "prebuild" "latest" "/opt/invoiceninja" "invoiceninja.tar.gz"

    msg_info "Restoring Data"
    cp /tmp/invoiceninja_backup/.env /opt/invoiceninja/
    cp -r /tmp/invoiceninja_backup/storage/* /opt/invoiceninja/storage/ 2>/dev/null || true
    cp -r /tmp/invoiceninja_backup/public_storage/* /opt/invoiceninja/public/storage/ 2>/dev/null || true
    rm -rf /tmp/invoiceninja_backup
    msg_ok "Restored Data"

    msg_info "Running Migrations"
    cd /opt/invoiceninja
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan optimize
    chown -R www-data:www-data /opt/invoiceninja
    chmod -R 755 /opt/invoiceninja/storage
    msg_ok "Ran Migrations"

    msg_info "Starting Services"
    systemctl start php8.4-fpm nginx supervisor
    msg_ok "Started Services"

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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/setup${CL}"
