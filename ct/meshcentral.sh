#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://meshcentral.com/ | Github: https://github.com/Ylianst/MeshCentral

APP="MeshCentral"
var_tags="${var_tags:-remote-management}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/meshcentral ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  CURRENT=$(node -p "require('/opt/meshcentral/node_modules/meshcentral/package.json').version" 2>/dev/null)
  LATEST=$(npm view meshcentral version 2>/dev/null)
  if [[ -z "$LATEST" ]]; then
    msg_error "Could not determine the latest MeshCentral version from npm"
    exit 250
  fi
  if [[ "$CURRENT" != "$LATEST" ]]; then
    msg_info "Stopping Service"
    systemctl stop meshcentral
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} from v${CURRENT} to v${LATEST}"
    cd /opt/meshcentral
    $STD npm install "meshcentral@${LATEST}"
    msg_ok "Updated ${APP} to v${LATEST}"

    msg_info "Starting Service"
    systemctl start meshcentral
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "${APP} is already at v${CURRENT}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
