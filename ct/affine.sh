#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/toeverything/AFFiNE

APP="AFFiNE"
var_tags="${var_tags:-knowledge;notes;workspace}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/affine ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE="v0.27.2"
  if check_for_gh_release "affine_app" "toeverything/AFFiNE" "${RELEASE}" "each release is tested individually before the version is updated. Please do not open issues for this"; then
    msg_info "Stopping Services"
    systemctl stop affine-web affine-worker
    msg_ok "Stopped Services"

    ensure_dependencies cmake

    create_backup /root/.affine/config /root/.affine/storage

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "affine_app" "toeverything/AFFiNE" "tarball" "${RELEASE}" "/opt/affine"

    msg_info "Rebuilding Application (Patience ~25 mins, don't close the console!)"
    cd /opt/affine
    source /root/.profile
    export PATH="/root/.cargo/bin:/root/.rbenv/shims:$PATH"

    set -a && source /opt/affine/.env && set +a

    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    export VITE_CORE_COMMIT_SHA=$(cat ~/.affine_app)

    # Initialize git repo (required for build process)
    export HUSKY=0
    $STD git init -q
    $STD git config user.email "build@local"
    $STD git config user.name "Build"
    $STD git add -A
    $STD git commit -q -m "update" --no-verify --allow-empty

    # Force Turbo to run sequentially
    mkdir -p /opt/affine/.turbo
    cat <<TURBO >/opt/affine/.turbo/config.json
{
  "concurrency": 1
}
TURBO

    $STD corepack enable
    $STD corepack prepare yarn@4.13.0 --activate
    $STD yarn config set enableTelemetry 0

    export NODE_OPTIONS="--max-old-space-size=2048"
    $STD yarn install
    $STD npm install -g typescript

    $STD yarn affine @affine/native build
    $STD yarn affine @affine/server-native build

    # Create architecture-specific symlinks
    ln -sf /opt/affine/packages/backend/native/server-native.node \
      /opt/affine/packages/backend/native/server-native.x64.node
    ln -sf /opt/affine/packages/backend/native/server-native.node \
      /opt/affine/packages/backend/native/server-native.arm64.node
    ln -sf /opt/affine/packages/backend/native/server-native.node \
      /opt/affine/packages/backend/native/server-native.armv7.node

    $STD yarn affine init
    $STD yarn affine build -p @affine/reader
    $STD yarn affine build -p @affine/server

    export NODE_OPTIONS="--max-old-space-size=4096"
    $STD yarn affine build -p @affine/web
    $STD yarn affine build -p @affine/admin

    # Copy web assets
    mkdir -p /opt/affine/packages/backend/server/static
    cp -r /opt/affine/packages/frontend/apps/web/dist/* /opt/affine/packages/backend/server/static/
    mkdir -p /opt/affine/packages/backend/server/static/admin
    cp -r /opt/affine/packages/frontend/admin/dist/* /opt/affine/packages/backend/server/static/admin/

    # Mobile manifest placeholder
    mkdir -p /opt/affine/packages/backend/server/static/mobile
    echo '{"publicPath":"/","js":[],"css":[],"gitHash":"","description":""}' \
      >/opt/affine/packages/backend/server/static/mobile/assets-manifest.json

    # Run migrations
    cd /opt/affine/packages/backend/server
    set -a && source /opt/affine/.env && set +a
    $STD node ./scripts/self-host-predeploy.js

    restore_backup

    msg_info "Starting Services"
    systemctl start affine-web affine-worker
    msg_ok "Started Services"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3010/admin${CL}"
