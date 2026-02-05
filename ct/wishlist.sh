#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dunky13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cmintey/wishlist

APP="Wishlist"
var_tags="${var_tags:-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/wishlist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "wishlist" "cmintey/wishlist"; then
    NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

    msg_info "Stopping Service"
    systemctl stop wishlist
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/wishlist-backup
    cp /opt/wishlist/.env /opt/wishlist-backup/.env
    cp -a /opt/wishlist/uploads /opt/wishlist-backup
    cp -a /opt/wishlist/data /opt/wishlist-backup
    msg_ok "Created Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wishlist" "cmintey/wishlist" "tarball"
    LATEST_APP_VERSION=$(get_latest_github_release "cmintey/wishlist")

    msg_info "Updating Wishlist"
    cd /opt/wishlist
    $STD pnpm install
    $STD pnpm svelte-kit sync
    $STD pnpm prisma generate
    sed -i 's|/usr/src/app/|/opt/wishlist/|g' $(grep -rl '/usr/src/app/' /opt/wishlist)
    export VERSION="v${LATEST_APP_VERSION}"
    export SHA="v${LATEST_APP_VERSION}"
    $STD pnpm run build
    $STD pnpm prune --prod
    chmod +x /opt/wishlist/entrypoint.sh

    msg_info "Restoring Backup"
    cp /opt/wishlist-backup/.env /opt/wishlist/.env
    cp -a /opt/wishlist-backup/uploads /opt/wishlist
    cp -a /opt/wishlist-backup/data /opt/wishlist
    rm -rf /opt/wishlist-backup
    msg_ok "Restored Backup"
    
    msg_ok "Updated Wishlist"
    msg_info "Starting Service"
    systemctl start wishlist
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3280${CL}"
