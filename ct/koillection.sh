#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koillection.github.io/

APP="Koillection"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/koillection ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "koillection" "benjaminjonard/koillection"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    PHP_VERSION="8.5" PHP_APACHE="YES" setup_php
    
    msg_info "Creating a backup"
    mv /opt/koillection/ /opt/koillection-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "koillection" "benjaminjonard/koillection" "tarball"

    msg_info "Updating Koillection"
    cd /opt/koillection 
    cp -r /opt/koillection-backup/.env.local /opt/koillection
    cp -r /opt/koillection-backup/public/uploads/. /opt/koillection/public/uploads/
    
    # Ensure APP_RUNTIME is in .env.local for CLI commands (upgrades from older versions)
    if ! grep -q "APP_RUNTIME" /opt/koillection/.env.local 2>/dev/null; then
      echo 'APP_RUNTIME="Symfony\Component\Runtime\SymfonyRuntime"' >> /opt/koillection/.env.local
    fi
    
    export COMPOSER_ALLOW_SUPERUSER=1
    export APP_RUNTIME='Symfony\Component\Runtime\SymfonyRuntime'
    $STD composer install --no-dev -o --no-interaction --classmap-authoritative
    $STD php bin/console doctrine:migrations:migrate --no-interaction
    $STD php bin/console app:translations:dump
    cd assets/ 
    $STD yarn install
    $STD yarn build
    mkdir -p /opt/koillection/public/uploads
    mkdir -p /opt/koillection/var/log
    chown -R www-data:www-data /opt/koillection/var/log
    chown -R www-data:www-data /opt/koillection/public/uploads
    rm -r /opt/koillection-backup
    
    # Ensure APP_RUNTIME is set in Apache config (for upgrades from older versions)
    if ! grep -q "APP_RUNTIME" /etc/apache2/sites-available/koillection.conf 2>/dev/null; then
      sed -i '/<VirtualHost/a\    SetEnv APP_RUNTIME "Symfony\\Component\\Runtime\\SymfonyRuntime"' /etc/apache2/sites-available/koillection.conf
    fi
    msg_ok "Updated Koillection"

    msg_info "Starting Service"
    systemctl start apache2
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
