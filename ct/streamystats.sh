#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fredrikburmester/streamystats

APP="Streamystats"
var_tags="${var_tags:-analytics;jellyfin}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  if [[ ! -d /opt/streamystats ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "streamystats" "fredrikburmester/streamystats"; then
    msg_info "Stopping Streamystats"
    systemctl stop streamystats-nextjs-app streamystats-job-server
    msg_ok "Stopped Streamystats"

    msg_info "Updating Bun"
    $STD bun upgrade
    msg_ok "Updated Bun"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "streamystats" "fredrikburmester/streamystats" "tarball"

    msg_info "Building Streamystats"
    cd /opt/streamystats
    $STD bun install --frozen-lockfile
    NEXT_TELEMETRY_DISABLED=1 NEXT_PUBLIC_VERSION="v$(cat ~/.streamystats)" $STD bun run build
    msg_ok "Built Streamystats"

    msg_info "Migrating Streamystats Database"
    $STD bun --env-file=/opt/streamystats_data/.env run db:migrate
    msg_ok "Migrated Streamystats Database"

    msg_info "Starting Streamystats"
    systemctl start streamystats-job-server streamystats-nextjs-app
    msg_ok "Started Streamystats"
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
