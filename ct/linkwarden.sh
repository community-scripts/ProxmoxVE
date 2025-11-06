#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkwarden.app/

APP="Linkwarden"
var_tags="${var_tags:-bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/linkwarden ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "linkwarden" "linkwarden/linkwarden"; then
    NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
    msg_info "Stopping Service"
    systemctl stop linkwarden
    msg_ok "Stopped Service"

    RUST_CRATES="monolith" setup_rust

    msg_info "Backing up data"
    mv /opt/linkwarden/.env /opt/.env
    [ -d /opt/linkwarden/data ] && mv /opt/linkwarden/data /opt/data.bak
    rm -rf /opt/linkwarden
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "linkwarden" "linkwarden/linkwarden"

    msg_info "Updating ${APP}"
    cd /opt/linkwarden
    $STD yarn
    $STD npx playwright install-deps
    $STD yarn playwright install
    mv /opt/.env /opt/linkwarden/.env
    $STD yarn prisma:generate
    $STD yarn web:build
    $STD yarn prisma:deploy
    [ -d /opt/data.bak ] && mv /opt/data.bak /opt/linkwarden/data
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start linkwarden
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache ~/.rustup
    rm -rf /root/.cache/yarn
    rm -rf /opt/linkwarden/.next/cache
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
