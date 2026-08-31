#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Karolis Stanelis (kstanelis)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

APP="Maintainerr"
var_tags="${var_tags:-media;arr;cleanup}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-24}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/maintainerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "maintainerr" "Maintainerr/Maintainerr"; then
    msg_info "Stopping Service"
    systemctl stop maintainerr
    msg_ok "Stopped Service"

    create_backup /opt/data /opt/maintainerr/.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball" "latest" "/opt/maintainerr"
    restore_backup
    NODE_VERSION="26" setup_nodejs

    msg_info "Rebuilding Maintainerr (Patience)"
    cd /opt/maintainerr
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD corepack enable
    $STD corepack prepare yarn@4.11.0 --activate
    $STD yarn config set enableTelemetry 0
    $STD yarn install --network-timeout 300000
    $STD yarn turbo build --concurrency=1
    cp -r apps/ui/dist apps/server/dist/ui
    cp -r apps/server/assets apps/server/dist/assets
    find apps/server/dist/ui -type f -not -path '*/node_modules/*' -print0 | xargs -0 sed -i "s,/__PATH_PREFIX__,,g"
    $STD yarn workspaces focus --all --production
    rm -rf /opt/maintainerr/.yarn/cache /opt/maintainerr/.turbo /opt/maintainerr/apps/ui
    sed -i '/^npm_package_version=/d;/^VERSION_TAG=/d' /opt/maintainerr/.env
    {
      echo "VERSION_TAG=stable"
      echo "npm_package_version=$(cat ~/.maintainerr)"
    } >>/opt/maintainerr/.env
    msg_ok "Rebuilt Maintainerr"

    msg_info "Starting Service"
    systemctl start maintainerr
    msg_ok "Started Service"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6246${CL}"
