#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://0xerr0r.github.io/blocky

APP="Blocky"
var_tags="${var_tags:-adblock}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/blocky ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "blocky" "0xERR0R/blocky"; then
    msg_info "Stopping Service"
    systemctl stop blocky
    msg_ok "Stopped Service"

    msg_info "Backup Config"
    mv /opt/blocky/config.yml /opt/config.yml
    msg_ok "Backed Up Config"

    msg_info "Removing Old Version"
    rm -rf /opt/blocky
    msg_ok "Removed Old Version"

    fetch_and_deploy_gh_release "blocky" "0xERR0R/blocky" "prebuild" "latest" "/opt/blocky" "blocky_*_Linux_x86_64.tar.gz"

    msg_info "Restore Config"
    mv /opt/config.yml /opt/blocky/config.yml
    msg_ok "Restored Config"

    msg_info "Starting Service"
    systemctl start blocky
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4000${CL}"
