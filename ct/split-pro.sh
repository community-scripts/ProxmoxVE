#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: johanngrobe
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/oss-apps/split-pro

APP="Split-Pro"
var_tags="${var_tags:-finance;expense-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/split-pro ]]; then
    msg_error "No Split Pro Installation Found!"
    exit
  fi

  if check_for_gh_release "split-pro" "oss-apps/split-pro"; then
    msg_info "Stopping Service"
    systemctl stop split-pro
    msg_ok "Stopped Service"

    create_backup /opt/split-pro/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "split-pro" "oss-apps/split-pro" "tarball"

    restore_backup

    msg_info "Building Application"
    cd /opt/split-pro
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    ln -sf /opt/split-pro_data/uploads /opt/split-pro/uploads
    $STD pnpm exec prisma migrate deploy
    msg_ok "Built Application"

    msg_info "Starting Service"
    systemctl start split-pro
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
