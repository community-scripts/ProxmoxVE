#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: quantumryuu | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://firefly-iii.org/

APP="Firefly"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d /opt/firefly ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "firefly" "firefly-iii/firefly-iii"; then
    systemctl stop apache2
    cp /opt/firefly/.env /opt/.env
    rm -rf /opt/storage
    cp -r /opt/firefly/storage /opt/storage

    if [[ -d /opt/firefly/dataimporter ]]; then
      cp /opt/firefly/dataimporter/.env /opt/dataimporter.env
      IMPORTER_INSTALLED=1
    fi

    fetch_and_deploy_gh_release "firefly" "firefly-iii/firefly-iii" "prebuild" "latest" "/opt/firefly" "FireflyIII-*.zip"
    setup_composer

    msg_info "Updating Firefly"
    rm -rf /opt/firefly/storage
    cp -r /opt/storage /opt/firefly/storage
    cp /opt/.env /opt/firefly/.env

    chown -R www-data:www-data /opt/firefly
    chmod -R 775 /opt/firefly/storage
    mkdir -p /opt/firefly/storage/framework/cache/data
    mkdir -p /opt/firefly/storage/framework/sessions
    mkdir -p /opt/firefly/storage/framework/views
    mkdir -p /opt/firefly/storage/logs
    mkdir -p /opt/firefly/bootstrap/cache
    chown -R www-data:www-data /opt/firefly/{storage,bootstrap/cache}
    cd /opt/firefly
    $STD runuser -u www-data -- composer install --no-dev --optimize-autoloader
    $STD runuser -u www-data -- composer dump-autoload -o

    $STD runuser -u www-data -- php artisan cache:clear
    $STD runuser -u www-data -- php artisan config:clear
    $STD runuser -u www-data -- php artisan route:clear
    $STD runuser -u www-data -- php artisan view:clear

    $STD runuser -u www-data -- php artisan migrate --seed --force
    $STD runuser -u www-data -- php artisan firefly-iii:upgrade-database
    $STD runuser -u www-data -- php artisan firefly-iii:laravel-passport-keys

    $STD runuser -u www-data -- php artisan storage:link || true
    $STD runuser -u www-data -- php artisan optimize
    msg_ok "Updated Firefly"

    if [[ "${IMPORTER_INSTALLED:-0}" -eq 1 ]]; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dataimporter" "firefly-iii/data-importer" "prebuild" "latest" "/opt/firefly/dataimporter" "DataImporter-v*.tar.gz"

      msg_info "Updating Firefly Importer"
      if [[ -f /opt/dataimporter.env ]]; then
        cp /opt/dataimporter.env /opt/firefly/dataimporter/.env
      fi
      chown -R www-data:www-data /opt/firefly/dataimporter
      msg_ok "Updated Firefly Importer"
    fi
    rm -rf /opt/storage /opt/.env /opt/dataimporter.env
    systemctl start apache2
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
