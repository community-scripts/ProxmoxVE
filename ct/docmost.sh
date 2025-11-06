#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

APP="Docmost"
var_tags="${var_tags:-documents}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/docmost ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! command -v node >/dev/null || [[ "$(/usr/bin/env node -v | grep -oP '^v\K[0-9]+')" != "22" ]]; then
    NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/docmost/docmost/main/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
  fi
  export NODE_OPTIONS="--max_old_space_size=4096"

  if check_for_gh_release "docmost" "docmost/docmost"; then
    msg_info "Stopping Service"
    systemctl stop docmost
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    cp /opt/docmost/.env /opt/
    cp -r /opt/docmost/data /opt/
    rm -rf /opt/docmost
    msg_ok "Data backed up"

    fetch_and_deploy_gh_release "docmost" "docmost/docmost"

    msg_info "Updating ${APP}"
    cd /opt/docmost
    mv /opt/.env /opt/docmost/.env
    mv /opt/data /opt/docmost/data
    $STD pnpm install --force
    $STD pnpm build
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start docmost
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
