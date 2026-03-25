#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pelican-dev/panel

APP="Pelican-Panel"
var_tags="${var_tags:-Gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/pelican-panel ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_mariadb
  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)
  setup_composer

  if [[ "$CURRENT_PHP" != "8.4" ]]; then
    msg_info "Migrating PHP $CURRENT_PHP to 8.4"
    $STD apt remove -y php"${CURRENT_PHP//./}"*
    PHP_VERSION="8.4" PHP_APACHE="YES" PHP_FPM="YES" setup_php
    msg_ok "Migrated PHP $CURRENT_PHP to 8.4"
  fi

  if check_for_gh_release "pelican-panel" "pelican-dev/panel"; then
    msg_info "Stopping Service"
    cd /opt/pelican-panel
    $STD php artisan down
    msg_ok "Stopped Service"

    cp -r /opt/pelican-panel/.env /opt/
    SQLITE_INSTALL=$(ls /opt/pelican-panel/database/*.sqlite 1>/dev/null 2>&1 && echo "true" || echo "false")
    $SQLITE_INSTALL && cp -r /opt/pelican-panel/database/*.sqlite /opt/
    rm -rf * .*
    fetch_and_deploy_gh_release "pelican-panel" "pelican-dev/panel" "prebuild" "latest" "/opt/pelican-panel" "panel.tar.gz"

    msg_info "Updating Pelican Panel"
    mv /opt/.env /opt/pelican-panel/
    $SQLITE_INSTALL && mv /opt/*.sqlite /opt/pelican-panel/database/
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD php artisan p:environment:setup
    $STD php artisan view:clear
    $STD php artisan config:clear
    $STD php artisan filament:optimize
    $STD php artisan migrate --seed --force
    chown -R www-data:www-data /opt/pelican-panel
    chmod -R 755 /opt/pelican-panel/storage /opt/pelican-panel/bootstrap/cache/
    msg_ok "Updated Pelican Panel"

    msg_info "Starting Service"
    $STD php artisan queue:restart
    $STD php artisan up
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/installer${CL}"
