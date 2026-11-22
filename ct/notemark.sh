#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/enchant97/note-mark

APP="Note Mark"
var_tags="${var_tags:-notes;markdown}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/notemark ]]; then
    msg_error "No Note Mark Installation Found!"
    exit
  fi

  if check_for_gh_release "notemark" "enchant97/note-mark"; then
    msg_info "Stopping Note Mark"
    systemctl stop notemark
    msg_ok "Stopped Note Mark"

    setup_go
    NODE_VERSION="24" NODE_MODULE="pnpm@11" setup_nodejs
    RUST_PROFILE="minimal" setup_rust
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "notemark" "enchant97/note-mark" "tarball"

    msg_info "Building Note Mark"
    $STD rustup target add wasm32-unknown-unknown
    cd /opt/notemark/frontend
    $STD pnpm install --frozen-lockfile
    $STD pnpm run wasm
    $STD pnpm run build
    cd /opt/notemark/backend
    $STD go tool sqlc generate
    CGO_ENABLED=0 $STD go build -ldflags "-X main.Version=$(cat ~/.notemark)" -o /opt/notemark/note-mark
    rm -rf /opt/notemark/frontend/node_modules /opt/notemark/frontend/renderer/target
    $STD go clean -cache -modcache
    msg_ok "Built Note Mark"

    msg_info "Starting Note Mark"
    systemctl start notemark
    msg_ok "Started Note Mark"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
