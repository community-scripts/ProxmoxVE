#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alexjustesen/speedtest-tracker

APP="Speedtest-Tracker"
var_tags="${var_tags:-monitoring}"
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

  if [[ ! -d /opt/speedtest-tracker ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "speedtest-tracker" "alexjustesen/speedtest-tracker"; then
    PHP_VERSION="8.4" PHP_FPM="YES" setup_php
    setup_composer
    NODE_VERSION="22" setup_nodejs
    setcap cap_net_raw+ep /bin/ping

    msg_info "Stopping Service"
    systemctl stop speedtest-tracker
    msg_ok "Stopped Service"

    msg_info "Updating Speedtest CLI"
    $STD apt update
    $STD apt --only-upgrade install -y speedtest
    msg_ok "Updated Speedtest CLI"

    msg_info "Creating Backup"
    cp -r /opt/speedtest-tracker /opt/speedtest-tracker-backup
    msg_ok "Backup Created"

    fetch_and_deploy_gh_release "speedtest-tracker" "alexjustesen/speedtest-tracker" "tarball" "latest" "/opt/speedtest-tracker"

    msg_info "Updating Speedtest Tracker"
    cp -r /opt/speedtest-tracker-backup/.env /opt/speedtest-tracker/.env
    cd /opt/speedtest-tracker
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --optimize-autoloader --no-dev
    $STD npm ci
    $STD npm run build
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    chown -R www-data:www-data /opt/speedtest-tracker
    chmod -R 755 /opt/speedtest-tracker/storage
    chmod -R 755 /opt/speedtest-tracker/bootstrap/cache
    msg_ok "Updated Speedtest Tracker"

    msg_info "Starting Service"
    systemctl start speedtest-tracker
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
