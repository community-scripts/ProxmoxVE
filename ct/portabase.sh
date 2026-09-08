#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://portabase.io

APP="Portabase"
var_tags="${var_tags:-database;backup}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d /opt/portabase ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "portabase" "Portabase/portabase"; then
    msg_info "Stopping Services"
    systemctl stop portabase portabase-tusd
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    cp /opt/portabase/.env /opt/portabase.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "portabase" "Portabase/portabase" "tarball"

    msg_info "Restoring Configuration"
    cp /opt/portabase.env.bak /opt/portabase/.env
    rm -f /opt/portabase.env.bak
    msg_ok "Restored Configuration"

    msg_info "Building Portabase"
    cd /opt/portabase
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export NEXT_TELEMETRY_DISABLED=1
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    cp -r /opt/portabase/.next/static /opt/portabase/.next/standalone/.next/static
    cp -r /opt/portabase/public /opt/portabase/.next/standalone/public
    mkdir -p /opt/portabase/.next/standalone/src/db
    cp -r /opt/portabase/src/db/migrations /opt/portabase/.next/standalone/src/db/migrations
    ln -sf /opt/portabase/.env /opt/portabase/.next/standalone/.env
    msg_ok "Built Portabase"

    msg_info "Starting Services"
    systemctl start portabase-tusd portabase
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
