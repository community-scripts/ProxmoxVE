#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZimengXiong/ExcaliDash

APP="ExcaliDash"
var_tags="${var_tags:-documents;drawing;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/excalidash ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "excalidash" "ZimengXiong/ExcaliDash"; then
    msg_info "Stopping Service"
    systemctl stop excalidash
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "excalidash" "ZimengXiong/ExcaliDash" "tarball"
    ln -sf /opt/excalidash_data/.env /opt/excalidash/backend/.env
    set -a && source /opt/excalidash_data/.env && set +a

    msg_info "Configuring Database Provider (${DATABASE_PROVIDER:-sqlite})"
    cd /opt/excalidash/backend
    sed -i '/datasource db {/,/}/ s/provider = env("[^"]*")/provider = "'"${DATABASE_PROVIDER:-sqlite}"'"/' prisma/schema.prisma
    mv prisma/migrations/"${DATABASE_PROVIDER:-sqlite}"/* prisma/migrations/
    rm -rf prisma/migrations/postgresql prisma/migrations/sqlite
    msg_ok "Configured Database Provider"

    msg_info "Rebuilding Application"
    $STD npm ci
    $STD npx prisma generate
    $STD npx tsc
    cd /opt/excalidash/frontend
    $STD npm ci
    $STD npm run build
    cp -r /opt/excalidash/frontend/dist/. /var/www/excalidash/
    msg_ok "Rebuilt Application"

    msg_info "Running Migrations"
    cd /opt/excalidash/backend
    $STD npx prisma migrate deploy
    msg_ok "Ran Migrations"

    msg_info "Starting Service"
    systemctl start excalidash
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
echo -e "${GATEWAY}${BGN}http://${IP}:6767${CL}"
