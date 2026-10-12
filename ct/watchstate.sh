#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arabcoders/watchstate

APP="WatchState"
var_tags="${var_tags:-media;plex;jellyfin;emby}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/watchstate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # the old master-YYYYMMDD-<sha> releases outrank the v* tags in the version sort
  if check_for_gh_release "watchstate" "arabcoders/watchstate" "" "" "v"; then
    msg_info "Stopping WatchState"
    systemctl stop watchstate-worker php8.5-fpm
    msg_ok "Stopped WatchState"

    create_backup /opt/watchstate/.env
    setup_composer
    NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "watchstate" "arabcoders/watchstate" "tarball" "latest" "/opt/watchstate" "" "v"
    restore_backup

    msg_info "Building WatchState"
    cd /opt/watchstate
    # the Redis cache (routes, event listeners) is namespaced by this version, so a release left at dev-master keeps serving the old one
    sed -i "s/'version' => 'dev-master'/'version' => 'v$(cat ~/.watchstate)'/" config/config.php
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    cd /opt/watchstate/frontend
    $STD bun install --frozen-lockfile --production
    NODE_ENV=production $STD bun run generate
    mv /opt/watchstate/frontend/exported /opt/watchstate/public/exported
    rm -rf /opt/watchstate/frontend/node_modules /opt/watchstate/frontend/.nuxt
    msg_ok "Built WatchState"

    msg_info "Migrating WatchState Database"
    $STD php /opt/watchstate/bin/console db:migrate --execute
    $STD php /opt/watchstate/bin/console db:index
    chown -R www-data:www-data /opt/watchstate_data
    msg_ok "Migrated WatchState Database"

    msg_info "Starting WatchState"
    systemctl start php8.5-fpm watchstate-worker
    msg_ok "Started WatchState"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}The first visitor creates the system user - open the URL right away${CL}"
