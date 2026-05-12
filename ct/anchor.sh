#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZhFahim/anchor

APP="Anchor"
var_tags="${var_tags:-notes;productivity;sync}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -f ~/.anchor ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "anchor" "ZhFahim/anchor"; then
    msg_info "Stopping Services"
    systemctl stop anchor-web anchor-server
    msg_ok "Stopped Services"

    msg_info "Backing up Configuration"
    cp /opt/anchor/.env /opt/anchor.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "anchor" "ZhFahim/anchor" "tarball"

    msg_info "Building Server"
    cd /opt/anchor/server
    $STD pnpm install --frozen-lockfile
    $STD pnpm prisma generate
    $STD pnpm build
    [[ -d src/generated ]] && mkdir -p dist/src && cp -R src/generated dist/src/
    msg_ok "Built Server"

    msg_info "Building Web Interface"
    cd /opt/anchor/web
    $STD pnpm install --frozen-lockfile
    SERVER_URL=http://127.0.0.1:3001 $STD pnpm build
    cp -r .next/static .next/standalone/.next/static
    cp -r public .next/standalone/public
    msg_ok "Built Web Interface"

    cp /opt/anchor.env.bak /opt/anchor/.env
    rm -f /opt/anchor.env.bak

    msg_info "Running Database Migrations"
    cd /opt/anchor/server
    set -a && source /opt/anchor/.env && set +a
    $STD pnpm prisma migrate deploy
    msg_ok "Ran Database Migrations"

    msg_info "Starting Services"
    systemctl start anchor-server anchor-web
    msg_ok "Started Services"
    msg_ok "Updated ${APP}"
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
