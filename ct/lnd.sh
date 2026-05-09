#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lightningnetwork/lnd | https://raspibolt.org/guide/lightning/

COMMUNITY_SCRIPTS_BASE_URL="${COMMUNITY_SCRIPTS_BASE_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_BASE_URL}/misc/build.func")
APP="LND"
var_tags="${var_tags:-bitcoin;lightning}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /etc/systemd/system/lnd.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP} LXC"
  export FUNCTIONS_FILE_PATH="$(curl -fsSL "${COMMUNITY_SCRIPTS_BASE_URL}/misc/install.func")"
  if [[ -z "$FUNCTIONS_FILE_PATH" || ${#FUNCTIONS_FILE_PATH} -lt 100 ]]; then
    msg_error "Failed to download install functions"
    exit 1
  fi
  type=update bash -c "$(curl -fsSL "${COMMUNITY_SCRIPTS_BASE_URL}/install/lnd-install.sh")"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} LND peer port:${CL} ${TAB}${BGN}9735${CL}"
echo -e "${INFO}${YW} RTL web UI:${CL} ${TAB}${BGN}http://${IP}:3000${CL} ${YW}(if enabled)${CL}"
