#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tianji.msgbyte.com/

APP="Tianji"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/tianji ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  setup_uv

  if check_for_gh_release "tianji" "msgbyte/tianji"; then
    NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/msgbyte/tianji/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs

    msg_info "Stopping Service"
    systemctl stop tianji
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    cp /opt/tianji/src/server/.env /opt/.env
    mv /opt/tianji /opt/tianji_bak
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "tianji" "msgbyte/tianji"

    msg_info "Updating ${APP}"
    cd /opt/tianji
    export NODE_OPTIONS="--max_old_space_size=4096"
    $STD pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile
    $STD pnpm build:static
    $STD pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false
    mkdir -p ./src/server/public
    cp -r ./geo ./src/server/public
    $STD pnpm build:server
    mv /opt/.env /opt/tianji/src/server/.env
    cd src/server
    $STD pnpm db:migrate:apply
    msg_ok "Updated ${APP}"

    msg_info "Updating AppRise"
    $STD uv pip install apprise cryptography --system
    msg_ok "Updated AppRise"

    msg_info "Starting Service"
    systemctl start tianji
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/tianji_bak
    rm -rf /opt/tianji/src/client
    rm -rf /opt/tianji/website
    rm -rf /opt/tianji/reporter
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:12345${CL}"
