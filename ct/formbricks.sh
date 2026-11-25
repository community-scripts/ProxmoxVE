#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/formbricks/formbricks

APP="Formbricks"
var_tags="${var_tags:-survey;feedback;forms}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-12288}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/formbricks ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "spicedb" "authzed/spicedb"; then
    msg_info "Stopping SpiceDB"
    systemctl stop spicedb
    msg_ok "Stopped SpiceDB"

    fetch_and_deploy_gh_release "spicedb" "authzed/spicedb" "binary"

    msg_info "Migrating SpiceDB Datastore"
    set -a && source /opt/formbricks_data/spicedb.env && set +a
    $STD spicedb datastore migrate head
    msg_ok "Migrated SpiceDB Datastore"

    msg_info "Starting SpiceDB"
    systemctl start spicedb
    msg_ok "Started SpiceDB"
  fi

  if check_for_gh_release "formbricks" "formbricks/formbricks"; then
    msg_info "Stopping Formbricks"
    systemctl stop formbricks
    msg_ok "Stopped Formbricks"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "formbricks" "formbricks/formbricks" "tarball"
    NODE_VERSION="24" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/formbricks/package.json)" setup_nodejs

    msg_info "Building Formbricks (Patience)"
    cd /opt/formbricks
    sed -i "s/\"version\": \"0.0.0\"/\"version\": \"$(cat ~/.formbricks)\"/" apps/web/package.json
    sed -i 's/^const nextConfig = {$/&\n  typescript: { ignoreBuildErrors: true },/' apps/web/next.config.mjs
    touch apps/web/.env
    $STD pnpm install --ignore-scripts --frozen-lockfile
    $STD sh apps/web/scripts/docker/read-secrets.sh pnpm build --filter=@formbricks/web...
    cp -r apps/web/.next/static apps/web/.next/standalone/apps/web/.next/
    cp -r apps/web/public apps/web/.next/standalone/apps/web/
    msg_ok "Built Formbricks"

    msg_info "Migrating Formbricks Database"
    set -a && source /opt/formbricks_data/.env && set +a
    $STD node packages/database/dist/scripts/apply-migrations.js
    $STD node apps/web/dist/authzed-cli/index.mjs upgrade prepare
    msg_ok "Migrated Formbricks Database"

    msg_info "Starting Formbricks"
    systemctl start formbricks
    msg_ok "Started Formbricks"
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
