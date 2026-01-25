#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: durzo
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/connorgallopo/Tracearr

APP="Tracearr"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -f /lib/systemd/system/tracearr.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "tracearr" "connorgallopo/Tracearr"; then
    msg_info "Stopping Services"
    systemctl stop tracearr postgresql redis
    msg_ok "Stopped Services"

    msg_info "Updating pnpm"
    PNPM_VERSION="$(curl -fsSL "https://raw.githubusercontent.com/connorgallopo/Tracearr/refs/heads/main/package.json" | jq -r '.packageManager | split("@")[1]' | cut -d'+' -f1)"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack prepare pnpm@${PNPM_VERSION} --activate
    msg_ok "Updated pnpm"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tracearr" "connorgallopo/Tracearr" "tarball" "latest" "/opt/tracearr.build"

    msg_info "Building Tracearr"
    export TZ=$(cat /etc/timezone)
    cd /opt/tracearr.build
    $STD pnpm install --frozen-lockfile --force
    $STD pnpm turbo telemetry disable
    $STD pnpm turbo run build --no-daemon --filter=@tracearr/shared --filter=@tracearr/server --filter=@tracearr/web
    rm -rf /opt/tracearr
    mkdir -p /opt/tracearr/{packages/shared,apps/server,apps/web,apps/server/src/db}
    cp -rf package.json /opt/tracearr/
    cp -rf pnpm-workspace.yaml /opt/tracearr/
    cp -rf pnpm-lock.yaml /opt/tracearr/
    cp -rf apps/server/package.json /opt/tracearr/apps/server/
    cp -rf apps/server/dist /opt/tracearr/apps/server/dist
    cp -rf apps/web/dist /opt/tracearr/apps/web/dist
    cp -rf packages/shared/package.json /opt/tracearr/packages/shared/
    cp -rf packages/shared/dist /opt/tracearr/packages/shared/dist
    cp -rf apps/server/src/db/migrations /opt/tracearr/apps/server/src/db/migrations
    cp -rf data /opt/tracearr/data
    mkdir -p /opt/tracearr/data/image-cache
    rm -rf /opt/tracearr.build
    cd /opt/tracearr
    $STD pnpm install --prod --frozen-lockfile --ignore-scripts
    $STD chown -R tracearr:tracearr /opt/tracearr
    msg_ok "Built Tracearr"

    msg_info "Configuring Tracearr"
    sed -i "s/^APP_VERSION=.*/APP_VERSION=$(cat /root/.tracearr)/" /data/tracearr/.env
    chmod 600 /data/tracearr/.env
    chown -R tracearr:tracearr /data/tracearr
    msg_ok "Configured Tracearr"

    msg_info "Starting Services"
    systemctl start postgresql redis tracearr
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
