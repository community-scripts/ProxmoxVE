#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.monicahq.com/

APP="Monica"
var_tags="${var_tags:-network}"
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
  if [[ ! -d /opt/monica ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

  if check_for_gh_release "monica" "monicahq/monica"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/monica/ /opt/monica-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "monica" "monicahq/monica" "prebuild" "latest" "/opt/monica" "monica-v*.tar.bz2"

    msg_info "Configuring monica"
    cd /opt/monica/
    cp -r /opt/monica-backup/.env /opt/monica
    cp -r /opt/monica-backup/storage/* /opt/monica/storage/
    $STD composer install --no-interaction --no-dev
    $STD yarn config set ignore-engines true
    $STD yarn install
    $STD yarn run production
    $STD php artisan monica:update --force
    chown -R www-data:www-data /opt/monica
    chmod -R 775 /opt/monica/storage
    msg_ok "Configured monica"

    msg_info "Starting Service"
    systemctl start apache2
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r /opt/monica-backup
    msg_ok "Cleaned"
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
