#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: jager
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/atuinsh/atuin

APP="Atuin Server"
var_tags="shell-history;server"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/atuin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Get latest version from GitHub releases
  LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/atuinsh/atuin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  CURRENT_VERSION=$(atuin --version | awk '{print $2}')

  if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    msg_info "Stopping Atuin Server"
    systemctl stop atuin-server
    msg_ok "Stopped Atuin Server"

    msg_info "Updating $APP to v${LATEST_VERSION}"
    # Download and run the official setup script
    curl -fsSL https://setup.atuin.sh | sh
    # Update the symlink
    ln -sf ~/.atuin/bin/atuin /usr/local/bin/atuin
    msg_ok "Updated $APP to v${LATEST_VERSION}"

    msg_info "Starting Atuin Server"
    systemctl start atuin-server
    msg_ok "Started Atuin Server"
  else
    msg_ok "No update required. ${APP} is already at v${CURRENT_VERSION}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Your Atuin server is now running at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL}"
echo -e "${INFO}${YW}To connect clients to this server:${CL}"
echo -e "${TAB}${BYW}atuin settings update sync_address http://${IP}:8888${CL}"
echo -e "${TAB}${BYW}atuin register --username <USERNAME> --password <PASSWORD>${CL}"
echo -e "${INFO}${YW}See ~/atuin-server-info.txt for detailed configuration options.${CL}"
