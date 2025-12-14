#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wallabag.org/

APP="Wallabag"
var_tags="${var_tags:-productivity;read-it-later}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/wallabag ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wallabag" "wallabag/wallabag"; then
    msg_info "Stopping Services"
    systemctl stop nginx php8.3-fpm
    msg_ok "Stopped Services"

    msg_info "Creating Backup"
    cp /opt/wallabag/app/config/parameters.yml /tmp/wallabag_parameters.yml.bak
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wallabag" "wallabag/wallabag" "prebuild" "latest" "/opt/wallabag" "wallabag-*.tar.gz"

    msg_info "Restoring Configuration"
    cp /tmp/wallabag_parameters.yml.bak /opt/wallabag/app/config/parameters.yml
    rm -f /tmp/wallabag_parameters.yml.bak
    msg_ok "Restored Configuration"

    msg_info "Running Migrations"
    cd /opt/wallabag
    $STD php bin/console cache:clear --env=prod
    $STD php bin/console doctrine:migrations:migrate --env=prod --no-interaction
    chown -R www-data:www-data /opt/wallabag
    chmod -R 755 /opt/wallabag/{var,web/assets}
    msg_ok "Ran Migrations"

    msg_info "Starting Services"
    systemctl start php8.3-fpm nginx
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
