#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01 | CanbiZ
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karlomikus/bar-assistant
# Source: https://github.com/karlomikus/vue-salt-rim
# Source: https://www.meilisearch.com/

APP="Bar-Assistant"
var_tags="${var_tags:-cocktails;drinks}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/bar-assistant ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "bar-assistant" "karlomikus/bar-assistant"; then
    msg_info "Stopping nginx"
    systemctl stop nginx
    msg_ok "Stopped nginx"

    PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="pdo-sqlite" setup_php

    create_backup /opt/bar-assistant/.env \
      /opt/bar-assistant/storage/bar-assistant

    fetch_and_deploy_gh_release "bar-assistant" "karlomikus/bar-assistant" "tarball" "latest" "/opt/bar-assistant"
    setup_composer

    restore_backup

    msg_info "Configuring Bar-Assistant"
    cd /opt/bar-assistant
    $STD composer install --no-interaction
    $STD php artisan migrate --force
    $STD php artisan storage:link
    $STD php artisan bar:setup-meilisearch
    $STD php artisan scout:sync-index-settings
    $STD php artisan config:cache
    $STD php artisan route:cache
    $STD php artisan event:cache
    chown -R www-data:www-data /opt/bar-assistant
    msg_ok "Configured Bar-Assistant"

    msg_info "Starting nginx"
    systemctl start nginx
    msg_ok "Started nginx"
  fi

  if check_for_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim"; then

    create_backup /opt/vue-salt-rim/public/config.js

    msg_info "Stopping nginx"
    systemctl stop nginx
    msg_ok "Stopped nginx"

    fetch_and_deploy_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim" "tarball" "latest" "/opt/vue-salt-rim"
    restore_backup

    msg_info "Configuring Vue Salt Rim"
    cd /opt/vue-salt-rim
    $STD npm install
    $STD npm run build
    msg_ok "Configured Vue Salt Rim"

    msg_info "Starting nginx"
    systemctl start nginx
    msg_ok "Started nginx"
  fi

  setup_meilisearch

  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
