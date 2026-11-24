#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/David-Crty/databasement

APP="Databasement"
var_tags="${var_tags:-backup;database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/databasement ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "databasement" "David-Crty/databasement"; then
    msg_info "Stopping Databasement"
    systemctl stop databasement-worker databasement-scheduler php8.5-fpm
    msg_ok "Stopped Databasement"

    setup_composer
    NODE_VERSION="22" setup_nodejs

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "databasement" "David-Crty/databasement" "tarball"

    msg_info "Updating Databasement"
    ln -sf /opt/databasement_data/.env /opt/databasement/.env
    sed -i "s/^APP_VERSION=.*/APP_VERSION=$(cat ~/.databasement)/" /opt/databasement_data/.env
    cd /opt/databasement
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD php artisan vendor:publish --force --tag=livewire:assets
    $STD npm ci --ignore-scripts
    $STD npm run build
    $STD php artisan migrate --force
    $STD php artisan optimize
    chown -R www-data:www-data /opt/databasement /opt/databasement_data
    msg_ok "Updated Databasement"

    msg_info "Starting Databasement"
    systemctl start php8.5-fpm databasement-worker databasement-scheduler
    msg_ok "Started Databasement"
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
