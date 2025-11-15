#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: quantumryuu | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://firefly-iii.org/

APP="Firefly"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d /opt/firefly ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "firefly" "firefly-iii/firefly-iii"; then
    systemctl stop apache2
    cp /opt/firefly/.env /opt/.env
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
      msg_info "Updating Firefly Importer"
      IMPORTER_RELEASE=$(curl -fsSL https://api.github.com/repos/firefly-iii/data-importer/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
      rm -rf /opt/firefly/dataimporter
      mkdir -p /opt/firefly/dataimporter
      curl -fsSL "https://github.com/firefly-iii/data-importer/releases/download/v${IMPORTER_RELEASE}/DataImporter-v${IMPORTER_RELEASE}.tar.gz" -o "/opt/DataImporter.tar.gz"
      tar -xzf /opt/DataImporter.tar.gz -C /opt/firefly/dataimporter
      if [[ -f /opt/dataimporter.env ]]; then
        cp /opt/dataimporter.env /opt/firefly/dataimporter/.env
      fi
      chown -R www-data:www-data /opt/firefly/dataimporter
      rm -f /opt/DataImporter.tar.gz
      msg_ok "Updated Firefly Importer"
    fi
    systemctl start apache2
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
