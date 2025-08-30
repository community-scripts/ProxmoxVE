#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kyantech/Palmr

APP="Palmr"
var_tags="${var_tags:-files}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/palmr_data ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "palmr" "kyantech/Palmr"; then
    msg_info "Stopping Services"
    systemctl stop palmr-frontend palmr-backend
    msg_ok "Stopped Services"

    cp /opt/palmr/apps/server/.env /opt/palmr.env
    fetch_and_deploy_gh_release "Palmr" "kyantech/Palmr" "tarball" "latest" "/opt/palmr"

    PNPM="$(jq -r '.packageManager' /opt/palmr/package.json)"
    NODE_VERSION="20" NODE_MODULE="$PNPM" setup_nodejs

    msg_info "Updating ${APP}"
    cd /opt/palmr/apps/server
    mv /opt/palmr.env /opt/palmr/apps/server/.env
    $STD pnpm install
    $STD pnpm dlx prisma generate
    $STD pnpm dlx prisma migrate deploy
    $STD pnpm dlx prisma db push
    $STD pnpm build

    cd /opt/palmr/apps/web
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    mv ./.env.example ./.env
    $STD pnpm install
    $STD pnpm build
    chown -R palmr:palmr /opt/palmr_data /opt/palmr
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start palmr-backend palmr-frontend
    msg_ok "Started Services"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
