#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/liketrek/TREK

APP="TREK"
var_tags="${var_tags:-travel;planning;collaboration}"
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

  if [[ ! -d /opt/trek ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "trek" "liketrek/TREK"; then
    MIGRATION=0
    grep -qF "ExecStart=/usr/bin/node --import tsx src/index.ts" \
      /etc/systemd/system/trek.service && MIGRATION=1

    msg_info "Stopping Service"
    systemctl stop trek
    msg_ok "Stopped Service"

    ensure_dependencies "libkitinerary-bin"

    create_backup /opt/trek/server/.env \
      /opt/trek/data \
      /opt/trek/uploads

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "trek" "liketrek/TREK" "tarball"

    msg_info "Building TREK"
    cd /opt/trek
    $STD npm ci
    $STD npm run build --workspace=shared
    $STD npm run build --workspace=client
    $STD npm run build --workspace=server
    msg_ok "Built TREK"

    msg_info "Setting up TREK Workspace"
    rm -rf /opt/trek/server/public
    mkdir -p /opt/trek/server/public/fonts
    cp -a /opt/trek/client/dist/. /opt/trek/server/public/
    cp -a /opt/trek/client/public/fonts/. /opt/trek/server/public/fonts/

    restore_backup

    rm -rf /opt/trek/server/data /opt/trek/server/uploads
    ln -s /opt/trek/data /opt/trek/server/data
    ln -s /opt/trek/uploads /opt/trek/server/uploads

    rm -rf /opt/trek/node_modules
    cd /opt/trek
    $STD npm ci --workspace=server --omit=dev
    msg_ok "Set up TREK Workspace"

    if [[ "$MIGRATION" == "1" ]]; then
      msg_info "Migrating TREK Service"
      cat <<EOF >/etc/systemd/system/trek.service
[Unit]
Description=TREK Travel Planner
Documentation=https://github.com/liketrek/TREK
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/trek/server
EnvironmentFile=/opt/trek/server/.env
Environment=XDG_CACHE_HOME=/tmp/trek-kf6-cache
Environment=QT_QPA_PLATFORM=offscreen
ExecStart=/usr/bin/node --require tsconfig-paths/register dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
      systemctl daemon-reload
      msg_ok "Migrated TREK Service"
    fi

    msg_info "Starting Service"
    systemctl start trek
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
