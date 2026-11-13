#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://colanode.com/

APP="Colanode"
var_tags="${var_tags:-collaboration;notes;chat}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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

  if [[ ! -d /opt/colanode ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "colanode" "colanode/colanode"; then
    msg_info "Stopping Services"
    systemctl stop colanode-server
    msg_ok "Stopped Services"

    create_backup /opt/colanode/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "colanode" "colanode/colanode" "tarball"

    msg_info "Rebuilding Application"
    cd /opt/colanode
    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD npm install
    $STD npm run build -w @colanode/core
    $STD npm run build -w @colanode/crdt
    $STD npm run build -w @colanode/server
    $STD npm run build -w @colanode/client
    $STD npm run build -w @colanode/ui
    $STD npm run build -w @colanode/web
    cp -r /opt/colanode/apps/web/dist/. /var/www/colanode/
    $STD npm prune --production
    unset NODE_OPTIONS
    msg_ok "Rebuilt Application"

    restore_backup

    msg_info "Starting Services"
    systemctl start colanode-server
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
echo -e "${INFO}${YW}Access it using the following URLs:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:4000${CL} (Web UI)"
echo -e "${INFO}${YW} Before using: import the self-signed cert into your browser:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:4000/colanode.crt${CL}"
echo -e "${INFO}${YW} Server URL to use inside the app:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:4000/config${CL}"
