#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usekaneo/kaneo

APP="Kaneo"
var_tags="${var_tags:-project-management;productivity}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/kaneo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kaneo" "usekaneo/kaneo"; then
    msg_info "Stopping Service"
    systemctl stop kaneo
    msg_ok "Stopped Service"

    create_backup /opt/kaneo/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kaneo" "usekaneo/kaneo" "tarball"

    PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/kaneo/package.json)
    NODE_VERSION="22" NODE_MODULE="pnpm@${PNPM_VERSION:-10.32.1}" setup_nodejs

    restore_backup

    msg_info "Configuring Kaneo"
    cat <<EOF >/opt/kaneo/apps/web/.env.production
VITE_API_URL=$(grep '^KANEO_API_URL=' /opt/kaneo/.env | cut -d= -f2-)
VITE_CLIENT_URL=$(grep '^KANEO_CLIENT_URL=' /opt/kaneo/.env | cut -d= -f2-)
EOF
    msg_ok "Configured Kaneo"

    msg_info "Building Kaneo"
    cd /opt/kaneo
    export NODE_OPTIONS="--max-old-space-size=4096"
    HUSKY=0 $STD pnpm install --frozen-lockfile
    $STD pnpm exec turbo build --filter=@kaneo/api --filter=@kaneo/web
    unset NODE_OPTIONS
    msg_ok "Built Kaneo"

    msg_info "Starting Service"
    systemctl start kaneo
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5173${CL}"
