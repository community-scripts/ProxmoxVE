#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/storyteller-platform/storyteller

APP="Storyteller"
var_tags="${var_tags:-media;ebook;audiobook}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/storyteller ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gl_release "storyteller" "storyteller-platform/storyteller"; then
    msg_info "Stopping Service"
    systemctl stop storyteller
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/storyteller/.env /opt/storyteller_env.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gl_release "storyteller" "storyteller-platform/storyteller" "tarball" "latest" "/opt/storyteller"

    msg_info "Restoring Configuration"
    mv /opt/storyteller_env.bak /opt/storyteller/.env
    msg_ok "Restored Configuration"

    msg_info "Rebuilding Storyteller"
    cd /opt/storyteller
    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD yarn install --network-timeout 600000
    $STD gcc -g -fPIC -rdynamic -shared web/sqlite/uuid.c -o web/sqlite/uuid.c.so
    export CI=1
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    export SQLITE_NATIVE_BINDING=/opt/storyteller/node_modules/better-sqlite3/build/Release/better_sqlite3.node
    $STD yarn workspaces foreach -Rpt --from @storyteller-platform/web --exclude @storyteller-platform/eslint run build
    mkdir -p /opt/storyteller/web/.next/standalone/web/.next/static
    cp -rT /opt/storyteller/web/.next/static /opt/storyteller/web/.next/standalone/web/.next/static
    if [[ -d /opt/storyteller/web/public ]]; then
      mkdir -p /opt/storyteller/web/.next/standalone/web/public
      cp -rT /opt/storyteller/web/public /opt/storyteller/web/.next/standalone/web/public
    fi
    mkdir -p /opt/storyteller/web/.next/standalone/web/migrations
    cp -rT /opt/storyteller/web/migrations /opt/storyteller/web/.next/standalone/web/migrations
    mkdir -p /opt/storyteller/web/.next/standalone/web/sqlite
    cp -rT /opt/storyteller/web/sqlite /opt/storyteller/web/.next/standalone/web/sqlite
    ln -sf /opt/storyteller/.env /opt/storyteller/web/.next/standalone/web/.env
    msg_ok "Rebuilt Storyteller"

    msg_info "Starting Service"
    systemctl start storyteller
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8001${CL}"
