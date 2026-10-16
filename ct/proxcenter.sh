#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/adminsyspro/proxcenter-ui

APP="ProxCenter"
var_tags="${var_tags:-proxmox;management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/proxcenter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "proxcenter" "adminsyspro/proxcenter-ui"; then
    msg_info "Stopping ProxCenter"
    systemctl stop proxcenter
    msg_ok "Stopped ProxCenter"

    NODE_VERSION="26" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "proxcenter" "adminsyspro/proxcenter-ui" "tarball"

    msg_info "Building ProxCenter"
    cd /opt/proxcenter/frontend
    $STD npm ci --legacy-peer-deps --ignore-scripts
    $STD npm run build:icons
    $STD npx prisma generate
    # the type check in next build runs out of heap at 2 GB
    NODE_OPTIONS="--max-old-space-size=4608" $STD npm run build
    msg_ok "Built ProxCenter"

    msg_info "Migrating Database"
    set -a && source /opt/proxcenter_data/.env && set +a
    $STD npx prisma migrate deploy
    $STD npx prisma db seed
    msg_ok "Migrated Database"

    msg_info "Starting ProxCenter"
    systemctl start proxcenter
    msg_ok "Started ProxCenter"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
