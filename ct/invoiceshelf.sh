#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://invoiceshelf.com/

APP="InvoiceShelf"
var_tags="${var_tags:-invoicing;finance;business}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/invoiceshelf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "invoiceshelf" "InvoiceShelf/InvoiceShelf"; then
    msg_info "Stopping Services"
    systemctl stop caddy
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/invoiceshelf/.env /opt/invoiceshelf.env.bak
    cp -r /opt/invoiceshelf/storage /opt/invoiceshelf_storage_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "invoiceshelf" "InvoiceShelf/InvoiceShelf" "tarball"

    msg_info "Restoring Data"
    cp /opt/invoiceshelf.env.bak /opt/invoiceshelf/.env
    rm -f /opt/invoiceshelf.env.bak
    cp -r /opt/invoiceshelf_storage_backup/. /opt/invoiceshelf/storage
    rm -rf /opt/invoiceshelf_storage_backup
    msg_ok "Restored Data"

    msg_info "Updating Application"
    cd /opt/invoiceshelf
    $STD composer install --no-dev --optimize-autoloader
    if command -v corepack >/dev/null 2>&1; then
      $STD corepack pnpm install
      $STD corepack pnpm run build
    else
      $STD pnpm install
      $STD pnpm run build
    fi
    $STD php artisan migrate --force
    $STD php artisan optimize:clear
    chown -R www-data:www-data /opt/invoiceshelf
    msg_ok "Updated Application"

    msg_info "Starting Services"
    systemctl start caddy
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
