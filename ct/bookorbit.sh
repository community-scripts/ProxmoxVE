#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bookorbit/bookorbit

APP="BookOrbit"
var_tags="${var_tags:-books;library;reading}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/bookorbit ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs

  if check_for_gh_release "bookorbit" "bookorbit/bookorbit"; then
    msg_info "Stopping Service"
    systemctl stop bookorbit
    msg_ok "Stopped Service"

    create_backup /opt/bookorbit/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bookorbit" "bookorbit/bookorbit" "tarball"

    msg_info "Rebuilding Application"
    cd /opt/bookorbit
    PNPM_VERSION=$(jq -r '.packageManager | ltrimstr("pnpm@")' /opt/bookorbit/package.json)

    $STD corepack prepare "pnpm@${PNPM_VERSION}" --activate
    $STD pnpm install --frozen-lockfile
    $STD pnpm --filter client run build-only
    $STD pnpm --filter server run build
    cp -r /opt/bookorbit/client/dist /opt/bookorbit/server/public
    mkdir -p /opt/bookorbit/server/migrations
    cp -r /opt/bookorbit/server/src/db/migrations/. /opt/bookorbit/server/migrations/
    chmod +x /opt/bookorbit/server/bin/kepubify/*
    restore_backup
    APP_VER=$(cat ~/.bookorbit)
    sed -i "s/^APP_VERSION=.*/APP_VERSION=v$APP_VER/" /opt/bookorbit/.env
    msg_ok "Rebuilt Application"

    msg_info "Updating Kobo Python Runtime"
    $STD uv pip install --python /opt/bookorbit-python/bin/python -r /opt/bookorbit/server/requirements/kobo-cloudscraper.txt
    msg_ok "Updated Kobo Python Runtime"

    msg_info "Starting Service"
    systemctl start bookorbit
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
