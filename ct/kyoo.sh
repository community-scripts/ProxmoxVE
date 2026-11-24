#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/zoriya/Kyoo

APP="Kyoo"
var_tags="${var_tags:-media;streaming}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_gpu="${var_gpu:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/kyoo ]]; then
    msg_error "No Kyoo Installation Found!"
    exit
  fi

  if check_for_gh_release "kyoo" "zoriya/Kyoo"; then
    msg_info "Stopping Kyoo"
    systemctl stop kyoo-scanner kyoo-api kyoo-transcoder kyoo-auth
    msg_ok "Stopped Kyoo"

    setup_go
    PYTHON_VERSION="3.14" setup_uv
    NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kyoo" "zoriya/Kyoo" "tarball"

    msg_info "Building Kyoo Auth"
    cd /opt/kyoo/auth
    $STD go build -o keibi
    msg_ok "Built Kyoo Auth"

    msg_info "Building Kyoo Transcoder"
    cd /opt/kyoo/transcoder
    $STD go build -o transcoder
    msg_ok "Built Kyoo Transcoder"

    msg_info "Building Kyoo API"
    cd /opt/kyoo/api
    $STD bun install --production
    $STD bun build --compile --compile-autoload-package-json --minify-whitespace --minify-syntax --target bun --outfile server ./src/index.ts
    msg_ok "Built Kyoo API"

    msg_info "Setting up Kyoo Scanner"
    cd /opt/kyoo/scanner
    $STD uv sync --locked --python 3.14
    msg_ok "Set up Kyoo Scanner"

    msg_info "Building Kyoo Web App"
    cd /opt/kyoo/front
    NODE_ENV=production $STD bun install --production
    $STD bun run web
    rm -rf /opt/kyoo/front/node_modules ~/.bun/install/cache
    msg_ok "Built Kyoo Web App"

    msg_info "Starting Kyoo"
    systemctl start kyoo-auth kyoo-transcoder kyoo-api kyoo-scanner
    msg_ok "Started Kyoo"
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
echo -e "${GATEWAY}${BGN}https://${IP}${CL}"
echo -e "${INFO}${YW}The library stays empty until videos are in /opt/kyoo_data/media (e.g. pct set <CTID> -mp0 /path/to/media,mp=/opt/kyoo_data/media)${CL}"
